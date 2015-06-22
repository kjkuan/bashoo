TypeA() { :; }

def $1 <(=() {
    obj_super "$@"
    self[attr1]=value1
    self[attr2]=value2
};
end_def)

def $1::func1 <(=() {
    echo ${self[attr1]}
};
end_def)

def $1::func2 <(=() {
    self[attr2]=value222
};
end_def)


def $1::TypeB <(=() {
    self[attr_a1]=aaa1
    self[attr_a2]=aaa2
};
end_def)
obj_inherit $1::TypeB TypeA

def $1::TypeB::method1 <(=() { echo "$__type#method1"; }; end_def)
def $1::TypeB::method2 <(=() {
    local -n mod; mod_self_to mod
    echo ${mod[attr1]}
};
end_def)


