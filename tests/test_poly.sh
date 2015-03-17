#!/usr/bin/env bash

set -eEu

source bashoo.sh

Shape() {
    local x y
    parse_args -su "x y" "$@"

    local -n __=$__attrs
    __[x]=$x; __[y]=$y
}

Shape::draw() { return 1; }
Shape::move_to() { local -n __=$__attrs; __[x]=$1; __[y]=$2; }
Shape::rel_move_to() {
    local -n __=$__attrs
    __[x]=$(( __[x] + $1 ))
    __[y]=$(( __[y] + $2 ))
}

Rectangle() {
    local x y width height
    parse_args -su "x y width height" "$@"

    local -n __=$__attrs
    __[width]=$width; __[height]=$height

    obj_super x=$x y=$y
}
obj_inherit Rectangle Shape

Rectangle::draw() {
    local -n __=$__attrs
    echo "Drawing a $__type at (${__[x]},${__[y]})," \
         "width ${__[width]}, height ${__[height]}"
}
Rectangle::width=() { local -n __=$__attrs; __[width]=$1; }
Rectangle::height=() { local -n __=$__attrs; __[height]=$1; }

Circle() {
    local x y radius
    parse_args -su "x y radius" "$@"

    local -n __=$__attrs
    __[radius]=$radius

    obj_super x=$x y=$y
}
obj_inherit Circle Shape

Circle::draw() {
    local -n __=$__attrs
    echo "Drawing a $__type at (${__[x]},${__[y]}), radius ${__[radius]}"
}
Circle::radius=() { local -n __=$__attrs; __[radius]=$1; }

do_something_with_shape() {
    local shape=$1
    obj_msg $shape draw
    obj_msg $shape rel_move_to 100 100
    obj_msg $shape draw
}

main() {
    local shape rectangle

    obj_new Rectangle x=10 y=20 width=5 height=6
    obj_new Circle x=15 y=25 radius=8

    for shape in "${DS[@]:0}"; do
        do_something_with_shape "$shape"
    done
    ds_pop_n ${#DS[*]}

    obj_new Rectangle x=0 y=0 width=15 height=15
    rectangle=${DS[-1]}; ds_pop

    obj_msg $rectangle width= 30
    obj_msg $rectangle draw
}

main

