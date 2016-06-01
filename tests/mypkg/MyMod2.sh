self::myfunc1 () {
    ds_push "This is myfunc1 from module MyMod2"
    self[modvar1]=xyz
    obj_msg $self myfunc2
}

self::myfunc2 () {
    ds_push "This is myfunc2 from module MyMod2: ${modvar1}"
}
