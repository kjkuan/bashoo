#!/usr/bin/env bash

set -eEu

source bashoo.sh

Shape() { obj_msg $__id move_to "$@"; }

Shape::draw() { ds_push_err "Not implemented!"; return 1; }

Shape::move_to() {
    local x y
    parse_args -su "x y" "$@"

    local -n self=$__self
    self[x]=$x; self[y]=$y
}

Shape::rel_move_to() {
    local x y
    parse_args -su "x y" "$@"

    local -n self=$__self
    self[x]=$(( self[x] + $x ))
    self[y]=$(( self[y] + $y ))
}

Rectangle() {
    local x y width height
    parse_args -su "x y width height" "$@"

    local -n self=$__self
    self[width]=$width; self[height]=$height

    obj_super x=$x y=$y
}
obj_inherit Rectangle Shape

Rectangle::draw() {
    local -n self=$__self
    echo "Drawing a $__type at (${self[x]},${self[y]})," \
         "width ${self[width]}, height ${self[height]}"
}
Rectangle::width=() { local -n self=$__self; self[width]=$1; }
Rectangle::height=() { local -n self=$__self; self[height]=$1; }

Circle() {
    local x y radius
    parse_args -su "x y radius" "$@"

    local -n self=$__self
    self[radius]=$radius

    obj_super x=$x y=$y
}
obj_inherit Circle Shape

Circle::draw() {
    local -n self=$__self
    echo "Drawing a $__type at (${self[x]},${self[y]}), radius ${self[radius]}"
}
Circle::radius=() { local -n self=$__self; self[radius]=$1; }

do_something_with_shape() {
    local shape=$1
    obj_msg $shape draw
    obj_msg $shape rel_move_to x=100 y=100
    obj_msg $shape draw
}

main() {
    local shape rectangle

    obj_new Rectangle x=10 y=20 width=5 height=6
    obj_new Circle x=15 y=25 radius=8

    for shape in "${DS[@]:0}"; do
        do_something_with_shape "$shape"
        obj_free $shape
    done
    ds_pop_n ${#DS[*]}

    obj_new Rectangle x=0 y=0 width=15 height=15
    rectangle=${DS[-1]}; ds_pop

    obj_msg $rectangle width= 30
    obj_msg $rectangle draw

    obj_free $rectangle
}

main

