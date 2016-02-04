#!/usr/bin/env bash
set -eEu

source bashoo.sh

load utils.sh
load test.sh


Shape() { # <x> <y> [color]
    local params=(x y color); local "${params[@]}"
    unpack "$@" "${params[*]}"
    [[ $x && $y ]] || return 1
    self[x]=$x
    self[y]=$y
    self[color]=${color:-"black"}
}
Shape::color() { ds_push "${self[color]}"; }
Shape::color=() { self[color]=$1; }
Shape::str() { ds_push "$__type(${self[color]})"; }
Shape::area() { return 1; }
Shape::draw() { return 1; }
Shape::position() { ds_push "${self[x]},${self[y]}"; }


Rectangle() { # <x> <y> <width> <height>
    local width height args=(obj_super)
    unpack "$@" "width height *args"
    [[ $width && $height ]] || return 1

    self[width]=$width self[height]=$height

    echo "${args[@]}"
    "${args[@]}"
}
obj_inherit Rectangle Shape

Rectangle::area() {
    ds_push $(( self[width] * self[height] ))
}
Rectangle::resize() {
    local width height
    unpack "$@" "width height"

    if [[ ! $width && ! $height ]]; then
        ds_push_err "At least one of width or height argument must be provided!"
        return 1
    fi

    case $width in 
        [+-]*) self[width]=$(( self[width] + width )) ;;
            *) self[width]=$width ;;
    esac
    case $height in 
        [+-]*) self[height]=$(( self[height] + height )) ;;
            *) self[height]=$height;;
    esac
}
Rectangle::draw() { # <canvas>
    local canvas=${1#*=}
    obj_msg $canvas add_shape $__id

    echo "Drawing $__type at (${self[x]}, ${self[y]}) on a canvas..."
}


Square() { # <x> <y> <size>
    local size args=(obj_super)
    unpack "$@" "size *args"
    [[ $size ]] || return 1

    "${args[@]}" width=$size height=$size 
}
obj_inherit Square Rectangle

Square::resize() {
    local width height
    unpack "$@" "width height"

    width=${width:-$height}
    height=${height:-$width}

    local old_width=${self[width]} old_height=${self[height]}

    obj_msg -p $self resize width=$width height=$height
    if [[ ${self[width]} != ${self[height]} ]]; then
        self[width]=$old_width; self[height]=$old_height
        ds_push_err "A square must remain a square after resizing!"
        return 1
    fi
}
Square::__unset__() { ds_push "I'm being freed!"; }


Canvas() {
    obj_super

    local array=array_$RANDOM
    declare -ga "$array=()"
    self[shapes]=$array
}
Canvas::__unset__() {
   unset ${self[shapes]}
}

Canvas::add_shape() { # <shape>
    local -n shapes=${self[shapes]}
    shapes+=("$1")
}
Canvas::push_shapes() {
    local -n shapes=${self[shapes]}
    ds_push "${shapes[@]}"
}



A() {
    self[attr1]=aaa
}
A::method_a1() {
    self[attr1]=aaa1

    local b=$1
    obj_msg $b method_b $__id

    self[attr1]+=11
}
A::method_a2() {
    self[attr2]=aaa2
    self[attr1]+=a
}
A::method_a3() {
    ds_push "A's attr1 is ${self[attr1]}"
    ds_push "A's attr2 is ${self[attr2]}"
}

B() {
    self[attr1]=bbb
}
B::method_b() {
    ds_push "B's attr1 is ${self[attr1]}"

    local a=$1
    obj_msg $a method_a2
}



test_1() {
    declare -p OBJ
    [[ "${OBJ[*]:-}" = "" && ${#OBJ[*]:-} = 0 ]]
}

test_object_creation_message_passing_and_polymorphism() {
    local rectangle square
    obj_new Rectangle x=110 y=34 width=10 height=20
    obj_new Square x=5 y=7 size=4 color=$'blood   \nred'

    ds_pop_to rectangle square

    obj_msg $square color
    [[ ${DS[-1]} = $'blood   \nred' ]]; ds_pop

    obj_msg $square color= red
    [[ $(obj_msg $square echo) = "Square(red)" ]]

    obj_msg $square resize width=+6 height=+4 || true
    echo "${DS[-1]}" | grep "A square must remain a square after resizing!*"; ds_pop

    obj_msg $square resize width=+6
    obj_msg $square area
    [[ ${DS[-1]} = 100 ]]; ds_pop

    obj_free $square
    [[ ${DS[-1]} = "I'm being freed!" ]]; ds_pop

    obj_msg $rectangle color
    [[ ${DS[-1]} = black ]]; ds_pop

    obj_msg $rectangle area
    [[ ${DS[-1]} = 200 ]]; ds_pop

    obj_msg $rectangle resize width=5 height=-7
    obj_msg $rectangle area
    [[ ${DS[-1]} = 65 ]]; ds_pop

    local canvas
    obj_new Canvas; ds_pop_to canvas
    obj_msg $rectangle draw canvas=$canvas
    obj_msg $canvas push_shapes
    [[ ${DS[-1]} = "$rectangle" ]]; ds_pop

    obj_free $rectangle
    obj_free $canvas
}


test_two_objects_messaging_each_other() {
    obj_new A
    obj_new B
    local a b
    ds_pop_to a b
    obj_msg $a method_a1 $b
    obj_msg $a method_a3

    [[ ${DS[-1]} = "A's attr2 is aaa2" ]]
    [[ ${DS[-2]} = "A's attr1 is aaa1a11" ]]
    [[ ${DS[-3]} = "B's attr1 is bbb" ]]

    ds_pop_n 3
    obj_free $a
    obj_free $b
}

test_obj_eval() {
    obj_new Shape x=1 y=2 color=green
    local shape; ds_pop_to shape
    obj_eval $shape '
        ds_push "${self[x]}" "${self[y]}" "${self[color]}"
    '
    local x y color
    ds_pop_to x y color
    [[ $x = 1 ]]
    [[ $y = 2 ]]
    [[ $color = green ]]
}



if [[ $BASH_SOURCE = "$0" ]]; then
    test_run_all
fi

