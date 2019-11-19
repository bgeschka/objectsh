# objectsh
PoC for Posix shell scripts with objects in ~66 lines

For examples check the lower part of objectsh.sh
you can run them with TEST=1 ./objectsh.sh

## Implements
* Objects with member functions
* Prototypal multi-inheritance
* $this
* getters are deep, setters are shallow

## Caveats
* ugly syntax as for object creation with "§ myobject" and accessors with "::" notation
* performance penalty on getters as for subshelling-echoing the return values

# Examples

```shell
§ animal
_walk(){
	echo "$($this :: name) can walk"
}
$animal :: walk = _walk

§ dog extends $animal
_bark(){
	echo "$($this :: name) can bark"
}
$dog :: bark = _bark
$dog :: name = "bert"
$dog :: walk #"bert can walk"
$dog :: bark #"bert can bark"
```
