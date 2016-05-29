#= This module provides a shared data stack, DS, meant for passing small amount
#= of data between function calls, and a set of ds_* functions to work with the
#= stack.
#=
#= Examples:
#=
#= To push on to the stack:    DS+=("item1" "item2" ...)
#=                      or:    ds_push "item1" "item2" ...
#=
#= To get the top item on the stack:    ${DS[-1]}
#= To pop the top item off the stack:   ds_pop
#=
#= To get the last $N item on the stack:     ${DS[@]: -N}
#= To pop the last $N items off the stack:   ds_pop $N
#
declare -ag DS

#= Usage: ds_push item1 item2 ...
#= Description:
#=     Push the specified arguments on to the stack. The last argument will be
#=     at the top of the stack.
#
ds_push() { DS+=("$@"); }

#= Usage: ds_pop
#= Description: Pop the top item off the stack.
#
ds_pop() { unset 'DS[-1]'; }

#= Usage: ds_pop_n [N]
#= Description: Pop the last N items off the stack.
#
ds_pop_n() {
    local len=${1:-1}
    while (( len-- )); do
        unset "DS[$(( ${#DS[@]} - 1 ))]" || return $?
    done
}

ds_dup() { ds_push "${DS[-1]}"; }
ds_dup_n() {
    local n=${1:-1} top=${DS[-1]}
    while (( n-- )); do ds_push "$top" || return $?; done
}
ds_swap() { local tmp; (( tmp=DS[-2], DS[-2]=DS[-1], DS[-1]=tmp )) || true; }

#= Usage: ds_echo
#= Description: Echo the top item on the stack.
#
ds_echo() { printf "%s\n" "${DS[-1]}"; }

#= Usage: ds_echo_pop
#= Description: Pop and echo the top item on the stack.
#
ds_echo_pop() { ds_echo && ds_pop; }

#= Usage: ds_pop_to [var_1 var_2 ... var_N]
#= Description:
#=     Pop the last N items off the stack and set the variables
#=     so that var_1=item_1 var_2=item_2 ... var_N=item_N,
#=     where item_N is the top item on the stack.
#
ds_pop_to() {
    ds_push $(( $# + 1 ))
    while (( $# > 0 )); do
        eval "$1=\${DS[${#DS[@]} - $# - 1]}" || return $?
        shift
    done
    ds_pop_n ${DS[-1]}
}

#= Usage: ds_push_err <error_message>
#= Description:
#=     Push an error message on to the stack along with a stack trace
#=     leading to this call. The caller should then return a non-zero
#=     status.
#=
#=     If the caller of the caller of this function, or the ERR trap,
#=    wish to handle the error, then it should pop the error message
#=    off the stack after doing so.
#
ds_push_err() {
    ds_push "Error from function
$(for ((i=0; i < ((${#FUNCNAME[*]} - 1)); i++)); do
      printf "  %s() in file %s:%d\n" \
          "${FUNCNAME[$i+1]}" "${BASH_SOURCE[$i+1]}" "${BASH_LINENO[$i]}"  
  done
)

$1"
}



