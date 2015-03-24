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
    local -n self=$__self
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
        MODULES[$1]=${DS[-1]}; ds_pop
    fi
}

# Default module for anything not explicitly defined in a module.
__globals() { :; }
mod_new __globals


# When called with in a method,  assign $__self of the module, in which
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
    local mpath=${1%.sh}
    if [[ ! ${MODULES[$mpath]:-} ]]; then
        local oIFS=$IFS; IFS=/
        local mods=($mpath.sh) pathes=()
        for ((i=0; i < ${#mods[*]}; i++)); do
            pathes[i]="${mods[*]:0:i+1}"
        done
        IFS=$oIFS

        local mod load_mod
        for mod in "${pathes[@]}"; do
            load_mod=$(load "$mod" "${mod%.sh}")
            eval $load_mod
            if [[ $load_mod != ': pass;' ]]; then
                mod_new ${mod%.sh}
            fi
        done
    fi
    obj_msg ${MODULES[${mpath}]} self
    ds_pop_to "${1##*/}"
}
