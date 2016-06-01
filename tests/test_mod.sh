#!/usr/bin/env bash

set -eEu
source bashoo.sh

export LOAD_SH_PATH="$LOAD_SH_PATH:$(cd "${0%/*}" && pwd)"

load mod.sh
load test.sh

load_mod mypkg/MyMod1.sh
load_mod mypkg/MyMod2.sh

ds_pop_to mymod1 mymod2

test_1() {
    obj_msg $mymod1 myfunc1
    [[ ${DS[-1]} == "This is myfunc2 from module MyMod1: abcd" ]]; ds_pop
    [[ ${DS[-1]} == "This is myfunc1 from module MyMod1: 1234" ]]; ds_pop
    [[ ${#DS[*]} == 0 ]]
}

test2() {
    obj_msg $mymod2 myfunc1
    [[ ${DS[-1]} == "This is myfunc2 from module MyMod2" ]]; ds_pop
    [[ ${DS[-1]} == "This is myfunc1 from module MyMod2: xyz" ]]; ds_pop
    [[ ${#DS[*]} == 0 ]]
}

if [[ $BASH_SOURCE = "$0" ]]; then
    test_run_all
fi
