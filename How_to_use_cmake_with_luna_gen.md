# Introduction #

Cmake's dependency-checking scheme is a bit confusing;
When there are multiple input and output files of a single luna-gen execution, it is very easy to make a cmake configuration in which all output files are always re-generated and re-compiled when no inputs changed at all.
The following way is a proper way to set cmake to avoid such problem.


# Assumption #

let's assume the following dependency:

Among input definition files:
```
"${luna_script}/luna_baselib.lua",
"${luna_script}/luna_mainlib.lua",
"${luna_script}/luna_physics.lua",
```
luna\_baselib.lua is the input definition file, and other lua files are "require"d from the luna\_baselib.lua.

Multiple outfiles are generated after running
```
lua "${LUNA_GEN}" "${luna_script}/luna_baselib.lua".
```

The output files are:
```
 "${luna_script}/luna_baselib.cpp"
 "${luna_script}/luna_mainlib.cpp"
 "${luna_script}/luna_physics.cpp"
 "${luna_script}/luna_baselib.h"
 "${luna_script}/luna_mainlib.h"
 "${luna_script}/luna_physics.h"
```

# CMake configuration #
Basically, you cannot list all the outputs in one add\_custom\_command function call. (Doing so causes some strange problems due to a cyclic dependency graph.)
Instead, you have to write add\_custom\_commands multiple times for each output file.
This can be easily done by defining a function as follows:
```
function (add_luna_baselib x)
     add_custom_command(
	OUTPUT "${luna_script}/${x}"
	DEPENDS "${luna_script}/luna_baselib.lua" "${luna_script}/luna_mainlib.lua" "${luna_script}/luna_physics.lua" "${LUNA_GEN}" 
	PRE_BUILD
	COMMAND lua "${LUNA_GEN}" "${luna_script}/luna_baselib.lua"
	)
endfunction()
```
Now, set dependency for all generated files:
```
add_luna_baselib("luna_baselib.cpp")
add_luna_baselib("luna_mainlib.cpp")
add_luna_baselib("luna_physics.cpp")
add_luna_baselib("luna_baselib.h")
add_luna_baselib("luna_mainlib.h")
```
The custom command is run only when the output is older than any of the dependent lua files. So this setting doesn't unnecessarily cause multiple ${LUNA\_GEN} invocations.

In the add\_executable section, list all the output files
```
add_executable(OgreFltk
 "${luna_script}/luna_baselib.cpp"
 "${luna_script}/luna_mainlib.cpp"
 "${luna_script}/luna_physics.cpp"
 "${luna_script}/luna_baselib.h"
 "${luna_script}/luna_mainlib.h"
 "${luna_script}/luna_physics.h"
  ...
```

This setting is safe only if the COMMAND generates all the output files at once. Otherwise, you need to add one add\_custom\_command for each necessary COMMAND in a similar way.