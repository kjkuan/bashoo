# This file should be sourced first so that you can use the load function to
# load other modules.
#
declare -A SOURCE_LOADED  # absolute file path -> module relative path

# This function is here because load.sh is usually the first file sourced
# and we want sane error reporting as early as possible before loading
# other files.
#
# Usage: trap 'print_stack_trace' ERR
# Description:
#    For any serious bash scripting, unless you are writing a library or would
#    better control over error handling, it's highly recommended that you
#    set -eEu for your script and then trap ERR to this function.
#
print_stack_trace() {
    local err_cmd=$BASH_COMMAND
    echo 
    if [[ ${DS:-} && ${DS[-1]} == Error* ]]; then
        echo "${DS[-1]}"; echo; ds_pop
    fi
    echo "Stack trace from ERR trap: --------"
    local i=0; while caller $((i++)); do :; done
    echo
    echo "Failed command is: $err_cmd"
} >&2


_find_sh_module() {
    local path mpath=$1
    local pathes oIFS=$IFS
    IFS=:; pathes=($LOAD_SH_PATH); IFS=$oIFS

    for path in "${pathes[@]}"; do
        path=$path/$mpath
        if [[ -e $path ]]; then
            readlink -f "$path"
            return
        fi
    done
}

# Usage: load <relative_source_path> [arg1 arg2 ...]
# Description:
#     Source the file by searching through LOAD_SH_PATH looking for the first
#     directory, X, such that $X/$relative_source_path exists, and then load it.
#
# Note: This function should only be called from the global/top level in a
#       source file.
#
load() {
    if [[ ! ${DS:-} ]]; then
        DS[0]=$(_find_sh_module "$1")
    else
        DS[${#DS[*]}]=$(_find_sh_module "$1")
    fi
    if [[ ! ${DS[-1]:-} ]]; then
        unset 'DS[-1]'
        echo "Source, $1, not found in \$LOAD_SH_PATH: $LOAD_SH_PATH" >&2
        return 1
    fi
    if [[ ! ${SOURCE_LOADED[${DS[-1]}]:-} ]]; then
        source "${DS[-1]}" "${@:2}"
        SOURCE_LOADED[${DS[-1]}]=$1
    fi
    unset 'DS[-1]'
}



# Add this file itself to the SOURCE_LOADED map.
# As a special case, the value of here is the path of the file that sourced
# this file.
SOURCE_LOADED[$(readlink -f "$BASH_SOURCE")]=$(readlink -f "$0")
