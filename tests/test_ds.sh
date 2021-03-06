#!/usr/bin/env bash
set -eEu

source bashoo.sh

load ds.sh 
load test.sh


test_1() {
    declare -p DS
    [[ "${DS[*]:-}" = "" && ${#DS[*]} = 0 ]]
}

test_2() {
    local items=(a b c "hello   world" 10 11 12)
    ds_push "${items[@]}"

    [[ ${DS[-1]} = 12 ]]
    ds_pop

    [[ ${DS[-1]} = 11 ]]
    [[ $(ds_echo) = 11 ]]
    ds_pop

    local tmp
    tmp=$(mktemp)
    ds_echo_pop > "$tmp"
    [[ $(<"$tmp") = 10 ]]

    [[ ${DS[-1]} = "hello   world" ]]
    local greeting; ds_pop_to greeting
    [[ $greeting = "hello   world" ]]
    [[ ${#DS[*]} = 3 ]]

    ds_pop_n 3
    [[ ${#DS[*]} = 0 ]]

    ds_push "${items[@]}"
    ds_pop_to d e f
    [[ $d = 10 ]]
    [[ $e = 11 ]]
    [[ $f = 12 ]]
}

test_3() {
    DS=(); ds_push a; ds_dup
    [[ ${#DS[*]} = 2 ]]
    [[ "a a" == "${DS[*]}" ]]
    ds_dup_n 2
    [[ ${#DS[*]} = 4 ]]
    [[ "a a a a" = "${DS[*]}" ]]
    ds_push b; ds_swap
    [[ "a a a b a" = "${DS[*]}" ]]
}



if [[ $BASH_SOURCE = "$0" ]]; then
    test_run_all
fi

