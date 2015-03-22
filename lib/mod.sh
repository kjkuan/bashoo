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
    local -n __=$__attrs
    __[__self]=$__self
    __[__type]=$__type
    local f
    for f in $(compgen -A function -X "!$__type::*" || true); do
        __[${f##*::}]="obj_msg $__self ${f##*::}"
    done
}
Module::attrs() { ds_push $__attrs; }

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


# When called with in a method, ds_push the $__attrs of the module, in which
# the calling object's type is defined.
#
mod_attrs() {
    # if object's type is defined in a module
    local mtype=${__type%%::*}
    if [[ ${mtype%/*} != $mtype ]]; then
        obj_msg ${MODULES[$mtype]} attrs
    else
        obj_msg __globals attrs
    fi
}

import() {
    local mpath=${1%.sh}
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

    obj_msg ${MODULES[${mpath}]} attrs
    ds_pop_to "${1##*/}"
}
