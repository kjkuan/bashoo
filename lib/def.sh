#
# This module simulates anonymous functions and closures in bash. 
# An anonymous function can be defined like this:
#
#    local var1 var2 var3 
#
#    local name
#    def_to name <<-'EOF'
#        ... function body goes here ... 
#        ... we will be able to access $var1 $var2 ...
#    EOF
#
# and you can call it like this while still in the same function that
# defines the def.
#
#     $name
#
# After you are done with $name, you should call def_unset $name to free
# the function:
#
#     def_unset $name
#
# If you are returning the def, don't def_unset it, and you need to save the
# local scope first, and returning it by pushing it to the DS stack along with
# a "def_call " prefix:
#
#     def_save $name "$(local -p)"  # save the local scope for the $name def.
#     ds_push "def_call $name"      # return it by pushing it onto DS.
#
# Obviously, you want to do this just before returning from the containing
# function so that you capture the final state of the locals.
#
# If your function doesn't modify local variables in its containing function
# then you can ds_push "def_call -r $name" instead, which will make the saved
# locals read-only when the function is called.
#
# Somewhere else you can then pop it off DS, and call it:
#
#     local the_func; ds_pop_to the_func
#     $the_func
#
# And finally, after you are done with $the_func, call def_unset to unset the
# function and its saved locals. 
#
#     def_unset $the_func
#
# See tests/test_def.sh for more examples.
#
#
######### RESTRICTIONS on calling returned def's ############
#
# If a returned def will modify the saved locals, then:
#
#   1) The returned def must not, either directly or indirectly, call itself.
#   2) A function should at most return one def. This is to ensure the
#      consistency of the saved locals.
#
#


DEF_LOCALS=()

def() {
    local f=$(<"$2")
    eval "$1()" "${f#*$'\n'}"
}
end_def() { declare -f ${1:-=}; }

def_to() {
    local def_name=$1
    local func_name=${def_name}_${#DEF_LOCALS[*]}
    eval "$func_name() {" "$(</dev/stdin)" $'\n}'
    local -n ref=$def_name; ref="$func_name"
}

def_save() { DEF_LOCALS[${1##*_}]=$2; }

def_unset() {
    if [[ $1 = def_call ]]; then shift; fi
    if [[ $1 = -r ]]; then shift; fi
    unset "DEF_LOCALS[${1##*_}]"
    unset -f "$1"
}

def_call() {
    local readonly=''
    if [[ $1 = -r ]]; then
        readonly=1; shift
    fi
    local oIFS=$IFS; IFS=$'\n'
    if [[ $readonly ]]; then
        eval local -r -- ${DEF_LOCALS[${1##*_}]}
        IFS=$oIFS; unset oIFS readonly
        "$1" "${@:2}"
    else
        eval local -- ${DEF_LOCALS[${1##*_}]}
        IFS=$oIFS; unset oIFS readonly
        "$1" "${@:2}"
        DEF_LOCALS[${1##*_}]=$(local -p)
    fi
}


