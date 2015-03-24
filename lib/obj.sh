eval $(load ds.sh)

# Our object pool, collecting all objects created by `obj_new`.
# It's actually a `obj_id -> attribute_map_id` map, where `obj_id` is
# a `numerical_id:type` string.
#
declare -gA OBJ=()

_obj_NEXT_ID=0    # the next numerical object ID to use by `obj_new`.
_obj_FREED_IDs=() # IDs of objects freed by `obj_free`.
# declare -gA _obj_ATTRIBUTES_*=()
#
# NOTE: _obj_ATTRIBUTES_* are dynamically created global associative arrays
#       that are used to hold an object's attributes, and each is suffixed
#       with obj_id and is created during obj_new().

declare -gA _OBJ_TYPE_PARENT  # type -> parent type
#
# An object's type is taken to be the name of its constructor function.
# Every type has a parent type. The root of the type hierarchy is the
# `Object` type. The super type of `Object` is still `Object`.

# Define the root object type.
Object() { :; }
Object::str() { ds_push $__id; }
Object::echo() { obj_msg $__id str; ds_echo_pop; }
Object::__unset__() { :; }


# Usage: obj_inherit <type_name> <parent_type_name>
# Description:
#     Setup the inheritance chain by specifying `type_name`'s parent/super
#     type. A type can have at most one parent type. If a type does not
#     declare its parent type by calling this function then its parent type
#     is implicitly assumed to be `Object`.
#
obj_inherit() {
    if [[ ! ${_OBJ_TYPE_PARENT[$1]:-} ]]; then
        _OBJ_TYPE_PARENT[$1]=$2
    fi
}


# Usage: obj_new <funcname> [arg1 arg2 ...]
# Description:
#     Create and track an object by calling the constructor, `funcname`, with
#     the passed arguments, and then push the object id on to the DS stack.
#     The name of the constructor function is also the object's type.
#
# NOTE:
#     Unless an object's super type is `Object`, in which case it's optional,
#     you MUST call `obj_super` in the object's constructor.
#     See `obj_super` for more details.
#
obj_new() {
    local -r __type=$1; shift
    local -r __id=$_obj_NEXT_ID:$__type
    local -r __self=_obj_ATTRIBUTES_$(( _obj_NEXT_ID++ ))
    declare -gA "$__self=([0]=$__id)"
    OBJ[$__id]=$__self

    # NOTE: We set [0] of the $__self associative array to $__id so that in
    #       a method in which the user has done: local -n self=$__self
    #       he/she can use $self instead of $__id, thus, "obj_msg $self method"
    #       reads nicer than "obj_msg $__id method".

    Object   # base constructor, currently does not thing.

    "$__type" "$@"

    ds_push "$__id"
}


# Usage: obj_super [arg1 arg2 ...]
# Description:
#     Call the constructor of the object's parent type on the object.
#     This function should only be called within a constructor, and calling
#     it is, in fact, mandatory for a type that is not a direct subtype of
#     Object.
#
obj_super() {
    if [[ ! ${__super:-} ]]; then
        local __super=${_OBJ_TYPE_PARENT[${__id#*:}]:-"Object"}
    else
        local __super=${_OBJ_TYPE_PARENT[$__super]:-"Object"}
    fi

    if [[ $__super = Object ]]; then
        : pass # since Object should be already called by obj_new().
    else
        $__super "$@"
    fi
}


# Usage: obj_free <obj_id>
# Description:
#     Delete the object referenced by `obj_id`.
#     Sends the __unset__ message to the object before unsetting it. This
#     give the object a chance to clean up any external resources.
#
obj_free() {
    if [[ ${OBJ[$1]} ]]; then
        obj_msg $1 __unset__
        unset ${OBJ[$1]}
        unset OBJ\["$1"\]
        _obj_FREED_IDs+=($1)
    else
        ds_push_err "Object '$1' doesn't exist!"
        return 1
    fi
}


# Usage: obj_msg [-p] <obj_id> <msg_name> [arg1 arg2 ...]
# Description:
#     Send the object referenced by `obj_id` the message specified by
#     `msg_name` and its arguments. The system will look for a function named
#     `obj_type::msg_name` by traversing up the inheritance chain(created by
#     the `obj_inherit` function), and the first such function found is
#     invoked or we reach the end of the chain and `Object::msg_name` will be
#     called which normally results in a command-not-found error.
#
#     If -p is specified then the search for the method starts from the parent
#     type of the object.
#
# Note:
#     `obj_type` is the type of the object as encoded in `obj_id`.
#      
obj_msg() {
    local from_super
    if [[ $1 = -p ]]; then from_super=1; shift; fi

    if [[ ! ${OBJ[$1]} ]]; then
        ds_push_err "Object '$__id' doesn't exist!"
        return 1
    fi
    local -r __id=$1 __type=${1#*:} msg_name=$2; shift 2

    local cur_type=$__type
    if [[ ${from_super:-''} ]]; then
        cur_type=${_OBJ_TYPE_PARENT[$cur_type]:-"Object"}
    fi

    while ! declare -F "$cur_type::$msg_name" >/dev/null 2>&1; do
        cur_type=${_OBJ_TYPE_PARENT[$cur_type]:-"Object"}
        [[ $cur_type = Object ]] && break
    done

    local -r __self=${OBJ[$__id]}
    "$cur_type::$msg_name" "$@"
}
