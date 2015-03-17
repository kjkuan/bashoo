#!/usr/bin/env bash
set -eEu

source bashoo.sh

eval $(
  load utils.sh
  load test.sh
)


Shape() { # <x> <y> [color]
    local x y color
    parse_args -us "x y color?" "$@"

    local -n __=$__attrs
    __[x]=$x
    __[y]=$y
    __[color]=${color:-"black"}
}
Shape::color() { local -n __=$__attrs; ds_push "${__[color]}"; }
Shape::color=() { local -n __=$__attrs; __[color]=$1; }
Shape::str() { local -n __=$__attrs; ds_push "$__type(${__[color]})"; }
Shape::area() { return 1; }
Shape::draw() { return 1; }
Shape::position() { local -n __=$__attrs; ds_push "${__[x]},${__[y]}"; }


Rectangle() { # <x> <y> <width> <height>
    local width height _args=(obj_super)
    parse_args -s "width height" "$@"

    local -n __=$__attrs
    __[width]=$width __[height]=$height

    "${_args[@]}"
}
obj_inherit Rectangle Shape

Rectangle::area() {
    local -n __=$__attrs
    ds_push $(( __[width] * __[height] ))
}
Rectangle::resize() {
    local width height
    parse_args -us "width? height?" "$@"

    if [[ ! $width && ! $height ]]; then
        ds_push_err "At least one of width or height argument must be provided!"
        return 1
    fi

    local -n __=$__attrs

    case $width in 
        [+-]*) __[width]=$(( __[width] + width )) ;;
            *) __[width]=$width ;;
    esac
    case $height in 
        [+-]*) __[height]=$(( __[height] + height )) ;;
            *) __[height]=$height;;
    esac
}
Rectangle::draw() { # <canvas>
    local canvas=${1#*=}
    obj_msg $canvas add_shape $__self

    local -n __=$__attrs
    echo "Drawing $__type at (${__[x]}, ${__[y]}) on a canvas..."
}


Square() { # <x> <y> <size>
    local size _args=(obj_super)
    parse_args -s "size" "$@"

    "${_args[@]}" width=$size height=$size 
}
obj_inherit Square Rectangle

Square::resize() {
    local width height _args=()
    parse_args -s "width? height?" "$@"

    width=${width:-$height}
    height=${height:-$width}

    local -n __=$__attrs

    local old_width=${__[width]} old_height=${__[height]}

    obj_msg -p $__self resize width=$width height=$height
    if [[ ${__[width]} != ${__[height]} ]]; then
        __[width]=$old_width; __[height]=$old_height
        ds_push_err "A square must remain a square after resizing!"
        return 1
    fi
}

Canvas() {
    obj_super
    local -n __=$__attrs

    local array=array_$RANDOM
    declare -ga "$array=()"
    __[shapes]=$array
}
Canvas::add_shape() { # <shape>
    local -n __=$__attrs
    local -n shapes=${__[shapes]}
    shapes+=("$1")
}
Canvas::push_shapes() {
    local -n __=$__attrs
    local -n shapes=${__[shapes]}
    ds_push "${shapes[@]}"
}



A() {
    local -n __=$__attrs
    __[attr1]=aaa
}
A::method_a1() {
    local -n __=$__attrs
    __[attr1]=aaa1

    local b=$1
    obj_msg $b method_b $__self

    __[attr1]+=11
}
A::method_a2() {
    local -n __=$__attrs
    __[attr2]=aaa2
    __[attr1]+=a
}
A::method_a3() {
    local -n __=$__attrs
    ds_push "A's attr1 is ${__[attr1]}"
    ds_push "A's attr2 is ${__[attr2]}"
}

B() {
    local -n __=$__attrs
    __[attr1]=bbb
}
B::method_b() {
    local -n __=$__attrs
    ds_push "B's attr1 is ${__[attr1]}"

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
    [[ ${DS[-1]} = $rectangle ]]; ds_pop
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
}



if [[ $BASH_SOURCE = $0 ]]; then
    test_run_all
fi

