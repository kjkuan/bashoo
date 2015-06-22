# Experimental!
#
# A module system built on top of Bashoo's object system.
#
# The primary purpose of a module is to provide namespace for variables and
# functions, including constructors.
#
# A module is an object. Its type is a direct subtype of the Module type.
# A module, when loaded, is instantiated by the object system, and tracked in
# the MODULES global associative array, keyed by the type of the module.
#


declare -gA MODULES=()  # module fullname -> module object

# Root of all module types.
Module() {
    self[__type]=$__type
    local f
    for f in $(compgen -A function -X "!$__type::*" || true); do
        self[${f##*::}]="obj_msg $__id ${f##*::}"
    done
}
Module::self() { ds_push $__self; }

mod_new() {
    obj_inherit $1 Module
    if [[ ${MODULES[$1]:-} ]]; then
        ds_push ${MODULES[$1]}
    else
        obj_new $1
    fi
}

# Default module for anything not explicitly defined in a module.
__globals() { :; }
mod_new __globals
MODULES[__globals]=${DS[-1]}; ds_pop


# When called with in a method,  assign $self of the module, in which
# the calling object's type is defined, to $1. Usually, $1,  should have
# been declared with local -n.
#
mod_self_to() {
    # if object's type is defined in a module
    local mtype=${__type%%::*}
    if [[ ${mtype%/*} != $mtype ]]; then
        obj_msg ${MODULES[$mtype]} self
    else
        obj_msg __globals self 
    fi
    ds_pop_to "$1"
}

import() {
    local -r __mpath=${1%.sh}
    if [[ ! ${MODULES[$__mpath]:-} ]]; then
        local oIFS=$IFS; IFS=/
        local mods=($__mpath.sh) pathes=()
        for ((i=0; i < ${#mods[*]}; i++)); do
            pathes[i]="${mods[*]:0:i+1}"
        done
        IFS=$oIFS; unset oIFS mods

        local __mod __load_mod
        for __mod in "${pathes[@]}"; do
            __load_mod=$(load "$__mod" "${__mod%.sh}")
            eval $__load_mod
            if [[ $__load_mod != ': pass;' ]]; then
                mod_new ${__mod%.sh}
                MODULES[${__mod%.sh}]=${DS[-1]}; ds_pop
            fi
        done
    fi
    obj_msg ${MODULES[${__mpath}]} self
    ds_pop_to "${1##*/}"
}
