#!/bin/sh
# Copyright (C) 2019 bjoern@geschka.org
#
# Simple object wrapper for posix shells
# '@' denotes creation of an object
# '::' are accessors for functions and variables
#
# usage example:
#	§ myobject
# 	$myobject :: a = "test1"
# 	$myobject :: b = "test2" "somestring"
# 	first="$($myobject :: a)" #results in first="test1"
# 	second="$($myobject :: b)" #results in second="test2 somestring"
#       
#       foo(){ echo "hello $1"; }
# 	$myobject :: foo = foo
# 	$myobject :: foo "bert" #calls foo and echoes "hello bert"
#
#       bar(){ $this :: a = "$1" }
# 	$myobject :: bar = bar #function assignment
# 	$myobject :: bar "meep" #call to member function bar, with args vector [meep]
#	$myobject :: a  # results in echoing "meep"
#
#	for more examples, inheritance and more see the tests 
#	you can run them with TEST=1 ./objectsh.sh
#
#	TODO
#	§ myobject free #removes the object from memory
#
#


_object_isfunction(){
	res="$(type "$*" 2>/dev/null)"
	case "$res" in
		*"is a function"*)
			return 0
			;;
	esac
	return 1
}

_object_get_aliased(){
	_arg="$(type "$*" 2>/dev/null | awk '{sub("`","",$NF);print $NF}')"
	echo "${_arg%%\'*}"
}

_object_counter=0
_object(){
	__this_objectid="obj_$_object_counter"
	_object_counter="$((_object_counter+1))"
	[ "$2" = "=" ] && __this_objectid="$(_object_get_aliased "$3")"
	[ "$2" = "extends" ] && prototype="$3"

	eval "
	$__this_objectid(){
		case \$1 in
			*::*)
				shift; #kick off the ::
				$__this_objectid call "$__this_objectid" "\"\$@\""
				;;
			call)
				__target=\$2
				shift;
				__field=\$2
				[ "\"x\$3\"" != 'x=' ] && {
					shift; shift;

					eval __val="\\\$_${__this_objectid}_\$__field" 

					if [ -z \"\$__val\" ] ;then
						[ -z "$prototype" ] && return
						eval $prototype call \"\$__target\" \"\$__field\"  \\\"\\\$@\\\"

						return
					fi

					if _object_isfunction \$__val; then
						this=\$__target eval \"\$__val\" \\\"\\\$@\\\"
					else
						echo \"\$__val\"
					fi
				}
				[ "\"x\$3\"" = 'x=' ] && {
					shift; shift; shift;
					__args="\"\$@\""
					eval "_${__this_objectid}_\$__field=\\"\$__args\\""

				}
				;;
		esac

	}
"

	eval export "$1=$__this_objectid"
}
alias @=_object



#thats all

#optional tests, you can cut this off if you like
testhead(){
	echo -e "${_C_BOLD}---------------$*---------------${_C_DFLT}"
}

assert(){
	name="$1"
	value="$2"
	expect="$3"
	[ -z "$value" ] && err "test $name has no value"
	[ -z "$expect" ] && err "test $name has no expected value"

	res="${_C_RED}failed${_C_DFLT}"
	[ "x$value" = "x$expect" ] && res="${_C_GREEN}passed${_C_DFLT}"
	echo -e "$res $name"
	[ "x$value" = "x$expect" ] || err "test failed $name with [ x$value = x$expect ]"
}

err(){
	echo "error:$*"
	exit 1
}

_C_BOLD="\e[1m"
_C_RED="\e[31m"
_C_GREEN="\e[32m"
_C_DFLT="\e[0m"

if [ -n "$TEST" ]; then #start tests


testhead "Setters"
@ setter_test
$setter_test :: a = "some foo"
assert "setting single string values to member variables" "$($setter_test :: a)" "some foo"
$setter_test :: b = 1234
assert "setting single integer values to member variables" "$($setter_test :: b)" "1234"
$setter_test :: c = "1test" "2test" "3test"
assert "setting multiple args values to member variables" "$($setter_test :: c)" "1test 2test 3test"
$setter_test :: d = 1 2 3 4 5 6 7 8 9
assert "setting multiple integer values to member variables" "$($setter_test :: d)" "1 2 3 4 5 6 7 8 9"




testhead "Passing objects by reference to functions"
@ pass_ref_test
$pass_ref_test :: a = 1336
passtest(){
	out="$($1 :: a)"
	assert "pass by reference test" "$out" "1336"
}
passtest $pass_ref_test




testhead "Member functions"
@ memfun
$memfun :: a = 1337
somefun(){
	echo "blah"
}
$memfun :: fun = somefun
assert "member function call test" "$($memfun :: fun)" "blah"

somefun2(){
	echo "blah $*"
}
$memfun :: fun2 = somefun2
assert "member function argument test" "$($memfun :: fun2 5 2 3 a b c)" "blah 5 2 3 a b c"

_asdf_test=1234
somefun3(){
	_asdf_test="$*"
}
$memfun :: fun3 = somefun3
$memfun :: fun3 5678
assert "member function change external variable" "$_asdf_test" "5678"

_asdf_test=1234
somefun4(){
	$this :: asdf = "$*"
}
$memfun :: fun4 = somefun4
$memfun :: fun4 5679
assert "member function change internal variable" "$($memfun :: asdf)" "5679"





testhead "Member changing \$this variables"
@ thistest
$thistest :: a = 1338
somefun2(){
	$this :: a
}
$thistest :: fun = somefun2
assert "self accessor \$this" "$($thistest :: fun)" "1338"






testhead "Inheritance model"
@ animal
walk(){
	echo "$($this :: name) can walk"
}
$animal :: walk = walk

@ dog extends $animal
bark(){
	echo "$($this :: name) can bark"
}
$dog :: bark = bark
$dog :: name = "bert"
assert "call first parent function" "$($dog :: walk)" "bert can walk"
assert "self call" "$($dog :: bark)" "bert can bark"







testhead "Multi Inheritance model, object scoping"
@ entity
exists(){
	echo "$($this :: name) can exist"
}
$entity :: exists = exists
saystuff(){
	echo "says: $*"
}
$entity :: saystuff = saystuff
setself_testvar(){
	$this :: testvar = "$*"
}
$entity :: setself_testvar = setself_testvar

@ animal2 extends $entity
walk(){
	echo "$($this :: name) can walk"
}
$animal2 :: walk = walk

@ dog2 extends $animal2
bark(){
	echo "$($this :: name) can bark"
}
$dog2 :: bark = bark
$dog2 :: name = "hugo"

$dog2 :: setself_testvar hello from dog
assert "call to second level prototype to change this value" "$($dog2 :: testvar)" "hello from dog"
assert "call to second level prototype to change this value not on second level parents" "x$($entity :: testvar)" "x"
assert "call to second level prototype to change this value not on first level parents" "x$($animal2 :: testvar)" "x"

assert "call to second level prototype with arguments" "$($dog2 :: saystuff hello im a dog)" "says: hello im a dog"
assert "call second level prototype" "$($dog2 :: exists)" "hugo can exist"
assert "call first level prototype" "$($dog2 :: walk)" "hugo can walk"
assert "call self call" "$($dog2 :: bark)" "hugo can bark"









testhead "Member functions argument globbing"
@ membertest_args_parent
fun2(){
	echo "[$1] [$2] [$3]"
}
$membertest_args_parent :: fun2 = fun2

@ membertest_args extends "$membertest_args_parent"
fun1(){
	echo "[$1] [$2] [$3]"
}
$membertest_args :: fun1 = fun1
callout="$($membertest_args :: fun1 "arg number one" "arg number two" "arg number three")"
assert "argument globbing first level member function" "$callout" "[arg number one] [arg number two] [arg number three]"
calloutp="$($membertest_args :: fun2 "arg number four" "arg number five" "arg number six")"
assert "argument globbing second level member function" "$calloutp" "[arg number four] [arg number five] [arg number six]"






fi #end tests
