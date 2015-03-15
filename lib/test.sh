

_test_get_tests() {
    shopt -s extdebug
    for fname in $(declare -f | grep ^test_ | cut -d' ' -f1); do
        declare -F $fname | 
            while read -r line; do
                [[ ${line#* * } = "$0" ]] || continue
                echo "$line"
            done 
    done | sort -nk2 | cut -d' ' -f1
    shopt -u extdebug
}

test_run_all() {
    local test_func
    for test_func in $(_test_get_tests); do
        $test_func
    done 
}
