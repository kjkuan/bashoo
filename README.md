## What is it?

Bashoo is a library/framework that makes it easy to write object-oriented Bash
programs. The goal is to develop tools and conventions that make writing
large and complex Bash programs easier and less error prone.

It is being developed and tested with Bash 4.3.

## Why?

If you are asking, WHY?! then Bashoo is probably not for you. Actually, I'd say
most people won't need it for general everyday shell scripting. If you think you
need it you are likely using the wrong tool for the job!

However, it is, for me, an interesting challenge to see how far I can push the
language, to make it work the way I want while still remain practical and useful.
It's not a toy project and I do intend to use it to build something bigger and useful ;-)

## Features and road map for v1.0.0

- [x] A dedicated global stack for passing values between
      function calls to reduce the need for command substitutions.
- [x] Better error reporting with stack traces.
- [x] An object and type system that supports single inheritance and polymorphism.
- [x] A module system that provides namespaces for variables and functions.
- [ ] Ability to mix-in modules to a type for greater code reuse.

Bashoo is still under development, suggestions or ideas to improve it
are very welcomed. Pull requests will be most appreciated!


## So what does it look like?

```bash

set -eEu  # Bashoo handles the ERR trap by showing the error line
          # and the stack trace. So we should take advantage of it.

source bashoo.sh
# NOTE: Make sure bashoo.sh is executable and bashoo/bin is in your PATH.

# A type is defined by a constructor function like this.
# The name of the function is the type.
Shape() {
    # Send the move_to message to the object itself with two named arguments.
    obj_msg $self move_to x=$x y=$y

    # NOTE: $self expands to $__id, a special variable that identifies the
    #       object itself. self is actually an associative array holding the
    #       object attributes. It is available within any constructors or methods.
}

# A method is defined as a function whose name is prefixed by <type>::
# where <type> is the type the method belongs to.
Shape::move_to() {
    # Check named arguments and assign them to local vars.
    # x and y are required. See lib/utils.sh#unpack for detailed spec.
    local x y; unpack "$@" "x y"
    [[ $x && $y ]] || {
        ds_push_err "Both x and y coordinates are required!"
        return 1
    }
    self[x]=$x; self[y]=$y
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
    echo "Drawing a $__type at (${self[x]}, ${self[y]})..."

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
