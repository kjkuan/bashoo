#!/usr/bin/env bash

set -eEu
source bashoo.sh
eval $(
  load def.sh
  load mod.sh
  load test.sh
)

export LOAD_SH_PATH=${BASH_SOURCE%/*}:$LOAD_SH_PATH

declare -n mod_x
import mod_w/mod_x


test_module_system() {
    [[ ${mod_x[attr1]} = value1 ]]
    [[ ${mod_x[attr2]} = value2 ]]
    declare -F mod_w/mod_x::func1
    declare -F mod_w/mod_x::func2
    declare -F mod_w/mod_x::TypeB
    declare -F TypeA

    [[ $(${mod_x[func1]}) = value1 ]]

    ${mod_x[func2]}
    [[ ${mod_x[attr2]} = value222 ]]

    local b
    obj_new ${mod_x[__type]}::TypeB; ds_pop_to b
    [[ $(obj_msg $b method1) = "mod_w/mod_x::TypeB#method1" ]]
    [[ $(obj_msg $b method2) = "value1" ]]
}


if [[ $BASH_SOURCE = $0 ]]; then
    test_run_all
fi

