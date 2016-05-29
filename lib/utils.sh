load ds.sh


_BASE_ID=$RANDOM

# Helper functions
q() { if [[ $@ ]]; then printf "%q" "$@"; fi; }
qn() { if [[ $@ ]]; then printf "%q\n" "$@"; fi; }


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


# Usage: unpack <arg1 arg2 ...> "param1 param2 ..."
# Description:
#     Unpack arguments into vars in the parent scope.
#
#     A named argument is of the form: name=value, where name must be a
#     valid bash identifier, unless it or the whole argument will be
#     collected by either a *parameter or a **parameter.
#     Each of the <arg1 arg2 ...> argument can be a named argument.
#
#     The last argument to the unpack function is a list of parameter names
#     that correspond to the names of the named arguments you wish to unpack.
#     'unpack' will only assign to variables named in the parameter list.
#
#     If a parameter is prefixed with '*' then it's assumed to be an indexed
#     array. If a parameter is prefixed with '**' then it's assumed to be an
#     associative array. There should only be at most one *param and one
#     **param. Any named arguments not assigned to the variables named in
#     the parameter list will be collected by the **param if it's specified;
#     otherwise they will be collected by the *param. (So, actually, you either
#     want to specify a *param or a **param, but not both).
#
# Example:
#
#     myfunc() {
#       local params=(arg1 arg2 arg3)
#       local -- "${params[@]}" args=(); local -A kws
#       unpack "$@" "${params[*]} *args"
#       echo $arg1
#       echo "$arg2"
#       echo $arg3
#       echo "${args[@]}"
#       echo "${kws[arg4]}"
#       echo "${kws[arg5]}"
#       echo "${kws[arg6]}"
#       echo "${kws[arg7]}"
#     }
#
#     myfunc arg1=value1 arg2="another  value" arg3 arg4 arg5 arg6=value6 arg7=value7
#
#   The output should be:
#
#     value1
#     another  value
#     arg3
#     arg4 arg5 arg6=value6 arg7=value7
#
#   If, however, the above unpack invocation is: unpack "$@" "${param[*]} *args **kws"
#   then the output would be:
#
#     value1
#     another  value
#
#     arg4
#     arg5
#     value6
#     value7
#
unpack() {
    while (($# > 1)); do

        # if the arg is named (i.e., it's a "name=value" pair),
        # or it has no = sign in it(i.e., it's just a single "value").
        #
        if [[ ${1%%=*} ]]; then

            # if the arg name is in the formal parameter list
            if [[ " ${!#} " == *" ${1%%=*} "* ]]; then
                printf -v "${1%%=*}" -- "%s" "${1#*=}"  # set it

            # else if there's a ** parameter that collects
            # unknown named args then assign its value under the named key.
            #
            # NOTE: if the arg has no = sign then its value is the same as
            #       its name.
            elif [[ " ${!#} " =~ \ \*\*([^* ]+)\  ]]; then
                printf -v "${BASH_REMATCH[1]}[${1%%=*}]" -- "%s" "${1#*=}"

            # else if there's a * parameter(an array) that collects unknown
            # args, then append the whole arg to the array.
            #
            elif  [[ " ${!#} " =~ \ \*([^* ]+)\  ]]; then
                printf -v "DS[${#DS[*]}]" "%q" "$1"
                eval "${BASH_REMATCH[1]}+=(${DS[-1]})"; ds_pop
            else
                ds_push_err "Unknown named argument: $1"; return 1
            fi
        else
            ds_push_err "Unknown unamed argument: $1"; return 1
        fi
        shift
    done
}


# Print the contents of a local file to stdout.
# The file content is subject to parameter expansions and process substitutions.
#
# Output lines(with optional leading space characters) that begin with the
# character sequence #: will be removed from the output. 
#
# In cases where variable assignment is needed, parameter expansion
# can be used to achieve the desired side effect.
#
bash_tpl() {
    local EOF_MARKER=EOF_$(LC_CTYPE=C tr -cd 'a-f0-9' </dev/urandom | head -c 16)
    [[ ${#EOF_MARKER} = 20 ]]
    (
        source <(echo "cat <<$EOF_MARKER
$(<"$1")
$EOF_MARKER
"       )
    ) | sed '/^[[:space:]]*#:.*$/d'
}
