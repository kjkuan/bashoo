#!/usr/bin/env bash

set -eEu
source bashoo.sh

eval $(
  load utils.sh 
  load test.sh
)

test_trap() {
    export -f trap
    local output=$("$BASH" <(cat <<'EOF'
trap '
    echo "hello world"
    echo "This is the first trap!"
' EXIT

trap 'echo "This
is the second trap!"' EXIT
EOF
))
    local expected="hello world
This is the first trap!
This
is the second trap!"

    [[ $output = "$expected" ]]


}

test_parse_args() {
    local  arg1=a arg2=b arg3=c _args=()

    parse_args "arg1 arg2 arg3" arg3=3 arg2=2 arg1=1 arg4=4
    [[ "$arg1 $arg2 $arg3" = "a b c" && ${#_args[*]} = 0 ]]

    parse_args -u "arg1 arg2 arg3" arg3=3 arg2=2 arg1=1 arg4=4 || true
    [[ $(echo "${DS[-1]}" | tail -1) = "Unknown argument: arg4=4" ]]; ds_pop

    parse_args -s "arg1 arg2 arg3" arg3=3 arg2=2 arg1=1 arg4=4 arg5=5
    [[ "$arg1 $arg2 $arg3" = "1 2 3" ]]
    [[ ${#_args[*]} = 2 ]]
    [[ ${_args[*]} = "arg4=4 arg5=5" ]]
}


if [[ $BASH_SOURCE = "$0" ]]; then
    test_run_all
fi


