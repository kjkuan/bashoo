#!/usr/bin/env bash

set -eEu
source bashoo.sh
eval $(
  load def.sh
  load test.sh
)

times() {
    local factor=$1

    local multiply
    def_to multiply <<-'EOF'
        ds_push "$(( factor * $1 ))"
	EOF
    def_save $multiply "$(local -p)"
    ds_push "def_call -r $multiply" 
}

counter() {
    local start=$1

    local increment
    def_to increment <<-'EOF'
        start=$(( start + ${1:-1} ))
        ds_push "$start"
	EOF
    def_save $increment "$(local -p)"
    ds_push "def_call $increment"
}

test_readonly_closure() {
    local x5; times 5; ds_pop_to x5
    local result
    $x5 3; ds_pop_to result
    [[ $result = 15 ]]
    def_unset $x5
}

test_writable_closure() {
    local incr; counter 1; ds_pop_to incr
    local result
    $incr; $incr 2; ds_pop_to result
    [[ $result = 4 ]]
    def_unset $incr
}

seq_squares() {
    local nums=(1 2 3 4 5 6 7 8 9 10)

    local square len=${#nums[*]}
    
    def_to square <<-'EOF'
        local i
        for ((i=0; i < len; i++)); do
            nums[i]=$(( nums[i] * nums[i] ))
        done
        ds_push "${nums[*]}"
	EOF
    $square
    def_save $square "$(local -p)"
    ds_push "def_call $square"
}

test_calling_from_parent_function_and_then_from_outside() {
    local square
    seq_squares; ds_pop_to square
    $square
    [[ ${DS[-1]} = "1 16 81 256 625 1296 2401 4096 6561 10000" ]]
    [[ ${DS[-2]} = "1 4 9 16 25 36 49 64 81 100" ]]
    ds_pop_n 2
    def_unset $square
}


if [[ $BASH_SOURCE = $0 ]]; then
    test_run_all
fi

