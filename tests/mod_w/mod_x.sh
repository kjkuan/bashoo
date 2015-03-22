TypeA() { :; }

def $1 <(=() {
    obj_super "$@"
    local -n mod=$__attrs

    mod[attr1]=value1
    mod[attr2]=value2
};
end_def)

def $1::func1 <(=() {
    local -n mod=$__attrs
    echo ${mod[attr1]}
};
end_def)

def $1::func2 <(=() {
    local -n mod=$__attrs
    mod[attr2]=value222
};
end_def)


def $1::TypeB <(=() {
    local -n mod=$__attrs
    mod[attr_a1]=aaa1
    mod[attr_a2]=aaa2
};
end_def)
obj_inherit $1::TypeB TypeA

def $1::TypeB::method1 <(=() { echo "$__type#method1"; }; end_def)
def $1::TypeB::method2 <(=() {
    local -n mod; mod_attrs; ds_pop_to mod
    echo ${mod[attr1]}
};
end_def)


