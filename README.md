## DESCRIPTION

Bashoo is a library that makes it easy to write object-oriented Bash
programs. Single inhertiance and polymorphism are supported.

The goal is to develop tools and conventions that make writing
large and complex Bash programs easier and less error prone.

It is being developed and tested with Bash 4.3.


## SYNOPSIS

```bash

set -eEu  # Bashoo handles the ERR trap by showing the error line
          # and the stack trace. So we should take advantage of it.

source bashoo.sh
# NOTE: Make sure bashoo.sh is executable and bashoo/bin is in your PATH.

# A type is defined by a constructor function like this.
# The name of the function is the type.
Shape() {
    # Send the move_to message to the $__self object with two named arguments.
    obj_msg $__self move_to x=$1 y=$2

    # NOTE: __self is a special variable that identifies the object itself.
    #       It's avaialbe within any constructors or methods so that an object
    #       can send messages to itself.
}

# A method is defined as a function whose name is prefixed by <type>::
# where <type> is the type the method belongs to.
Shape::move_to() {
    # Check named arguments and assign them to local vars.
    # x and y are required. See lib/utils.sh#parse_args for detailed spec.
    local x y
    parse_args -s "x y" "$@"

    local -n __=$__attrs
    # __ is now our associative array holding the object attributes.
    # We can set object attributes by assigning [key]=value to it.

    __[x]=$1; __[y]=$2
}

# An abstract method, needs to be implemented by a subtype.
Shape::draw() {
    # Push an error message to the DS stack. Such error message will be shown
    # by Bashoo's ERR trap handler.
    ds_push_err "Not implemented!"
    return 1

    # NOTE: DS is global array avaialbe in Bashoo. It is used for
    #       passing results between function calls. ds_* are functions
    #       for manipulating the DS array. See lib/ds.sh for details.
}

Circle() {
    # A subtype must call the constructor of its super type to initialize
    # the object.
    obj_super "$@"
}
obj_inherit Circle Shape  # make Circle a subtype of Shape.

Circle::draw() {
    local -n __=$__attrs
    echo "Drawing a $__type at (${__[x]}, ${__[y]})..."

    # NOTE: $__type expands to the object's type
}

main() {
    # Create a Circle object. obj_new pushes the object reference to the
    # DS stack. We then pop it off and into the circle local var.
    local circle
    obj_new Circle x=5 y=10; ds_pop_to circle

    obj_msg $circle move_to x=7 y=4
    obj_msg $circle draw
    obj_free $circle   # We should free the object when we are done with it.
}
main
```

See [here](tests/test_poly.sh) for a longer example using Bashoo for
Jim Weirich's OO [problem](http://onestepback.org/articles/poly/).

More examples can be found in the [tests/](tests) directory.
