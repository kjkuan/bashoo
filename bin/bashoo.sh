export LOAD_SH_PATH=$(cd "${BASH_SOURCE%/*}/../lib" && pwd
    )"${LOAD_SH_PATH:+:$LOAD_SH_PATH}"

source "${BASH_SOURCE%/*}/../lib/load.sh"
trap print_stack_trace ERR

load utils.sh
load obj.sh
