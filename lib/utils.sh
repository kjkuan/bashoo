eval $(load ds.sh)


_BASE_ID=$RANDOM

# Create an empty global array and push is name to DS.
# Example usage:
#   local -n my_array; array_new -A
#   my_array=${DS[-1]}; ds_pop
#   .... Use my_array just like a normal associative array ...
#   unset my_array
#
array_new() {
    local name=array_$((_BASE_ID++))
    declare -g "$@" -- "$name=()"
    ds_push "$name"
}

# This overrides the trap builtin to append commands to a signal.
#
trap() {
    local option has_option
    OPTIND=1
    while getopts ':lp' option; do
        case $option in
            l|p) has_option=1 ;;
            -) break ;;
        esac
    done
    if [[ ${has_option:-''} ]]; then
        builtin trap "$@"; return $?
    fi
    shift $((OPTIND - 1))
    if [[ $# = 1 ]] || [[ $1 = - && $# = 2 ]]; then
        # ie, resetting signal to default
        builtin trap "$@"; return $?
    fi
    local cmd=$1; shift
    local signal line lines=()
    for signal in "$@"; do
        readarray lines <<<"$(builtin trap -p "$signal")"
        if [[ ! $(echo ${lines[*]}) ]]; then
            # no existing trap set for the signal
            builtin trap "$cmd" "$signal"
            continue
        fi
        lines[0]="builtin trap ${lines[0]#trap }"
        lines[-1]="${lines[-1]%\'*}
                   $cmd' $signal"
        eval "${lines[*]}"
    done
}

# Usage: parse_args [-u][-s] <spec> "$@"
# Description:
#     Parse the name=value arguments in "$@", checking them against spec.
#     Exit 1 if "$@" fails the spec.
#
#     If -u is specified then any unknown argument fails the spec. 
#
#     If -s is specified and the spec is verified successfully, then, also
#     sets the variables named by the arg names to their values, and any
#     unknown arguments are append to the _args var an array.
#
# Note:
#    The local variable names, __arg, __argname, and __spec, are reserved 
#    by this function. The implication is that the -s option won't be able
#    to set the variables in its parent scope.
#      
#
# Example:
#   # At the start of a function:
#   local arg1 arg2 arg3=() arg4=() _args
#   parse_args -s "arg1 arg2? arg3* arg4+" "$@"
#
#   arg1 is required.
#   arg2 is optional.
#   arg3 can appear zero or more times.
#   arg4 must appear at least once.
#
#   Lets say, "$@" is "arg1=value1" "arg3=value3" "arg4=4" "arg4=44" "arg5=5"
#
#   If "$@" passed the spec then the local var, arg1 will be set to "value1";
#   arg2 will be not be set; arg3 will be set to ("value3"); arg4 will be set
#   to (4 44); _args will be set to (5).
#   
#
parse_args() {
    local option check_unknown= set_vars=
    OPTIND=1
    while getopts ':us' option "$@"; do
        case $option in
            u) check_unknown=1 ;;
            s) set_vars=1 ;;
           \?) ds_push_err "Invalid option: -$option"; return 1 ;;
        esac
    done
    shift $(($OPTIND - 1))

    # parse the spec
    local s arg; local -A __spec
    for s in $1; do
        arg=${s%[?*+]}; s=${s##$arg}
        __spec[$arg]=${s:-1}
    done
    shift

    # validate arg name, count the args, and collect unknown args
    local __argname __unknown_args=(); local -A __args=()
    for arg; do
        __argname=${arg%%=*}
        [[ $__argname =~ ^[a-zA-Z_][0-9a-zA-Z_]*$ ]] || {
            ds_push_err "Invalid argument name: $__argname"
            return 1
        }
        if [[ ${__spec[$__argname]:-} ]]; then
            (( __args[$__argname]+=1 ))
        elif [[ $check_unknown ]]; then
            ds_push_err "Unknown argument: $arg"; return 1
        else
            __unknown_args+=("$arg")  # collect unknown args
        fi
    done

    # check the arg counts against the spec
    local count
    for __argname in "${!__spec[@]}"; do
        count=${__args[$__argname]:-0}
        case ${__spec[$__argname]} in
            1) (( count == 1 )) || {
                    ds_push_err "Exactly one '$__argname' argument is allowed!"
                    return 1
               } ;;
           \?) (( count <= 1 )) || {
                    ds_push_err "'$__argname' argument may only appear at most once!"
                    return 1
               } ;;
           \+) (( count >= 1 )) || {
                    ds_push_err "'$__argname' argument must appear at least once!"
                    return 1
               } ;;
         esac
     done

     # set args that passed the spec
     if [[ $set_vars ]]; then
         unset option check_unknown set_vars s arg count
         local __arg

         for __arg; do
             __argname=${__arg%%=*}
             [[ ${__spec[$__argname]:-} ]] || continue

             if [[ ${__args[$__argname]} != 1 ]]; then
                 eval "$__argname+=( $(q "${__arg#*=}") )"
             else
                 eval "$__argname=$(q "${__arg#*=}")"
             fi
         done
         if [[ ${__unknown_args:-} ]]; then
             _args+=("${__unknown_args[@]}")
         fi
     fi
}



