# We define a module as an object from a singleton class that inherits from
# the `Module` class. The class of the module object is the fully qualified
# name of the module.
#
# For example:
#
#     MyPackage::MyMod () { obj_super:; }; obj_inherit MyPackage::MyMod Module
#     MyPackage::MyMod::func1 () {
#         echo func1 from module $__type, calling func2...
#         $__type::func2
#     }
#     MyPackage::MyMod::func2 () { echo func2 from module $__type; }
#
#     obj_new MyPackage::MyMod
#     mymod=${DS[-1]}; ds_pop
#     obj_msg $mymod func1
#
# Above code defines a module named, `MyPackage::MyMod`, with two functions,
# `func1` and `func2` in it. Then, we create the module object, saves it in
# `$mymod`, and then calls the `func1` in it.
#
# Notice that since module functions are methods of the module object,
# invoking a function of a module is exactly the same as invoking
# a method on the module object. Moreover, to call another function(e.g., `func2`
# here, for example) in the same module from a module function, it's possible
# to simply expand `$__type::func2` and then call the function directly without
# going through `obj_msg`(i.e., `obj_msg $self func2`).
#
# Now, writing all that to create a module is tedious at best and error prone
# at worst. Therefore, a `load_mod` function is introduced. Similar to `load()`,
# it takes a relative path to a bash source file. The difference is that the
# relative path of the file is assumed to be the name of the module(with `/`
# replaced with `::`), and all functions in it that are named like
# `self::func_name` will become methods of the module.
#
# For example, the above example can be written as a file at `MyPackage/MyMod.sh`
# with these two functions:
#
#     self::func1 () {
#         echo func1 from module $__type, calling func2...
#         $__type::func2
#     }
#     self::func2 () { echo func2 from module $__type; }
#
# And, it can be used like this:
#
#     load_mod MyPackage/MyMod
#     mymod=${DS[-1]}; ds_pop
#     obj_msg $mymod func1
#
# `load_mod` will take care of loading and instantiating the module object,
# and if a module has been loaded previously, then the same module object
# will be returned(pushed to `DS`) instead.
#
#
# A special function, `self::init`, can be defined in a module to be
# the constructor of the module, and it will be called when `load_mod` creates
# the module object. Though, remember to call `obj_super` in it. If no
# such constructor is defined, then one will be provided automatically:
#
#     self::init () { obj_super; }
#



# Keep tracks of all instantiated module objects.
declare -gA MOD  # Fully qualified module name --> module object id

# Root class of all modules
Module() { :; }



# Usage: `load_mod` `<relative_module_path>`
#
# Load a file as a module and push the initialized module object to `DS`
#
load_mod() {
    __load_mod_helper "$1" || return 1
    if [[ ${SOURCE_LOADED[${DS[-1]}]:-} ]]; then
        ds_push ${MOD[${DS[-2]}]}
        return 0
    fi
    source <(
        sed -re "$(cat <<EOF
            s|^\s*(function )?self::init(\s*\(\s*\)\s*[{(])|${DS[-2]}\2|
            s|^\s*(function )?self::([^[:space:]]+\s*\(\s*\)\s*[{(])|${DS[-2]}::\2|
EOF
        )" "${DS[-1]}"
        echo "if ! declare -F ${DS[-2]} >/dev/null; then ${DS[-2]} () { obj_super; }; fi"
        echo "obj_inherit ${DS[-2]} Module"

    ) || return 1

    SOURCE_LOADED[${DS[-1]}]=$1; ds_pop
    obj_new "${DS[-1]}"; MOD[${DS[-2]}]=${DS[-1]}
    ds_swap; ds_pop
}

__load_mod_helper() {
    if [[ $1 == /* ]]; then
        ds_push_err "Module path must be relative!(because module directory path maps to package name)"
        return 1
    fi

    local modpath; modpath=$(_find_sh_module "$1") || {
        ds_push_err "Module, $1, not found in \$LOAD_SH_PATH: $LOAD_SH_PATH"
        return 1
    }

    local pkg modname
    modname=${1##*/}; modname=${modname%.sh}
    [[ $modname =~ [a-zA-Z_][a-zA-Z0-9_-]* ]] || {
        ds_push_err "Invalid module name: $modname"
        return 1
    }
    if [[ $1 == */* ]]; then
        pkg=${1%/*}
        pkg=$(set -f; IFS=/; parts=(${pkg:-})
          for part in "${parts[@]}"; do
              if [[ ${part:-} ]]; then result+=("$part"); fi
          done
          echo "${result[*]:-}"
        )
        pkg=${pkg////::}; [[ $pkg =~ [a-zA-Z_][a-zA-Z0-9_-]* ]] || {
            ds_push_err "Invalid package name: $pkg"
            return 1
        }
    fi
    ds_push "${pkg:+$pkg::}$modname" "$modpath"
}
