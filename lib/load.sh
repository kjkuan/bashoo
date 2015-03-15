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
#    For any serious bash scripting, it's highly recommended that you
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


# Helper functions
q() { if [[ $@ ]]; then printf "%q" "$@"; fi; }
qn() { if [[ $@ ]]; then printf "%q\n" "$@"; fi; }


# Usage: eval $(load <relative_source_path> [arg1 arg2 ...])
# Description:
#     Source the file by searching through LOAD_SH_PATH looking for the first
#     directory, X, such that $X/$relative_source_path exists, and then load it.
#
load() {
    local path mpath=$1; shift
    local pathes oIFS=$IFS
    IFS=:; pathes=($LOAD_SH_PATH); IFS=$oIFS

    for path in "${pathes[@]}"; do
        path=$path/$mpath
        [[ ${SOURCE_LOADED[$path]:-""} ]] && return

        if [[ -e $path ]]; then
            path=$(q "$(readlink -f "$path")")

            # NOTE: Non-local bash variables are dynamically scoped!
            #       This is why we don't source the module within this function
            #       because doing so would expose all local variables here
            #       to any non-local variables of the same name in the
            #       sourced file.
            # 
            #       Moreoever, sourcing within a function causes any
            #       declarations of associative array variables in
            #       the sourced file to be declared in a function, and
            #       thus, defaults to local scope unless -g is specified.
            #
            echo '[[ ${SOURCE_LOADED['$path']:-} ]] || {'
            echo source $path $(qn "$@") \;
            echo SOURCE_LOADED\[$path\]=$(q "$mpath") \;
            echo '};'
            return
        fi
    done
    echo "echo 'Source, $(q "$mpath"), not found in" \
         "\$LOAD_SH_PATH: $(q "$LOAD_SH_PATH")' >&2; false;"
}



# Add this file itself to the SOURCE_LOADED map.
# As a special case, the value of here is the path of the file that sourced
# this file.
SOURCE_LOADED[$(readlink -f "$BASH_SOURCE")]=$(readlink -f "$0")
