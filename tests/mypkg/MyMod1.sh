self::init() { 
    obj_super
    self[modvar1]=1234
}

self::myfunc1 () {
    ds_push "This is myfunc1 from module MyMod1: ${self[modvar1]}"
    self[modvar1]=abcd
    $__type::myfunc2
}

self::myfunc2 () {
    ds_push "This is myfunc2 from module MyMod1: ${self[modvar1]}"
}
