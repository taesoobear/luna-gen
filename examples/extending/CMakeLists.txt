
# -*- mode: cmake; -*-
cmake_minimum_required(VERSION 2.8)

include_directories(
	/usr/include/lua5.1
	../..
)

project (mathlib)
set(src
	main.cpp
	../../luna.cpp
	)
set(luna_script "${CMAKE_SOURCE_DIR}")
set(LUNA_GEN "${CMAKE_SOURCE_DIR}/../../luna_gen.lua")

add_custom_command(
	OUTPUT "${luna_script}/binddef.cpp"
	DEPENDS "${luna_script}/binddef.lua" "${LUNA_GEN}" 
	PRE_BUILD
	COMMAND lua "${LUNA_GEN}" "${luna_script}/binddef.lua"
)

add_library(mathlib SHARED
	${src}
	"${CMAKE_SOURCE_DIR}/binddef.cpp" # important. without this, luna_gen doesn't run.
	)
# this will create mathlib.so 
set_target_properties(mathlib PROPERTIES PREFIX "")
