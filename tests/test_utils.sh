#!/usr/bin/env bash

set -eEu
source bashoo.sh

load utils.sh 
load test.sh

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

test_unpack() {
    local  arg1=a arg2=b arg3=c args=(); local -A kws=()
    unpack arg3=3 arg2=2 arg1=1 "arg1 arg2 arg3"
    [[ "$arg1 $arg2 $arg3" = "1 2 3" && ${#args[*]} = 0 && ${#kws[*]} = 0 ]]

    local  arg1=a arg2=b arg3=c args=(); local -A kws=()
    unpack arg3=3 arg2=2 arg1=1 arg4=4 "arg1 arg2 arg3" || true
    [[ "$arg1 $arg2 $arg3" = "1 2 3" && ${#args[*]} = 0 && ${#kws[*]} = 0 ]]
    [[ $(echo "${DS[-1]}" | tail -1) == "Unknown named argument: arg4=4" ]]; ds_pop

    local  arg1=a arg2=b arg3=c args=(); local -A kws=()
    unpack arg3=3 arg2=2 arg1=1 arg4=4 arg5 arg6 "arg1 arg2 arg3 *args"
    [[ "$arg1 $arg2 $arg3" = "1 2 3" && "${args[*]}" = "arg4=4 arg5 arg6" && ${#kws[*]} = 0 ]]

    local  arg1=a arg2=b arg3=c args=(); local -A kws=()
    unpack arg3=3 arg2=2 arg1=1 arg4=4 arg5 arg6 "arg1 arg2 arg3 **kws"
    [[ "$arg1 $arg2 $arg3" = "1 2 3" && "${#args[*]}" = 0 ]]
    [[ ${kws[arg4]} = 4 && ${kws[arg5]} = arg5 && ${kws[arg6]} = arg6 && ${#kws[*]} = 3 ]]
}


if [[ $BASH_SOURCE = "$0" ]]; then
    test_run_all
fi


