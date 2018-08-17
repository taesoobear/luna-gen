# -*- mode: cmake; -*-
cmake_minimum_required(VERSION 2.6)

# uncomment to see actual gcc/devenv command lines
#set (CMAKE_VERBOSE_MAKEFILE  ON)

project (test)

set(EXECUTABLE_OUTPUT_PATH ${test_SOURCE_DIR}/bin/)
set(LUNA_GEN ${test_SOURCE_DIR}/../luna_gen.lua)

include(${test_SOURCE_DIR}/modules.cmake)

if(UNIX)
  set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}")
  include(FindPkgConfig)
  find_package(Lua51 REQUIRED)
  message("include directories:")
  message(${LUA_INCLUDE_DIR} "\n")
	add_definitions(-Wno-deprecated)
else()
	set(LUA_INCLUDE_DIR "${test_SOURCE_DIR}/../Lua5.1.4/include")
	set(LUA_LIBRARY "${test_SOURCE_DIR}/../lua5.1.4/lua5.1.lib")
    set(LINK_FLAGS "${LINK_FLAGS} -mwindows -mconsole")
	add_definitions(-D_CONSOLE)
endif()

include_directories(
	${LUA_INCLUDE_DIR}
	${test_SOURCE_DIR}/..
	${test_SOURCE_DIR}
	${test_SOURCE_DIR}/../../MotionSynthesisLib/RigidBody
	)


#   # simple skeleton code. this will be wrapped in a function: add_luna_test
#   # typical dependency thing. 
#	add_custom_command(
#		OUTPUT "${test_SOURCE_DIR}/generated/test_x.cpp"
#		DEPENDS "${LUNA_GEN}" "${test_SOURCE_DIR}/test_x.lua"
#		PRE_BUILD
#		COMMAND lua "${LUNA_GEN}" "${test_SOURCE_DIR}/test_x.lua"
#	)
#	# param: executable file source files
#	add_executable("test_x"
#		"./generated/test_x.cpp"
#		"main.cpp"
#		)
#	# param: executable file libraries
#	target_link_libraries("test_x" ${LUA_LIB})

function(add_luna_test x)
	message("add_luna_test ${x}")
	add_custom_command(
	OUTPUT "${test_SOURCE_DIR}/generated/test_${x}.cpp"
	DEPENDS "${LUNA_GEN}" "${test_SOURCE_DIR}/test_${x}.lua"
	PRE_BUILD
	COMMAND lua "${LUNA_GEN}" "${test_SOURCE_DIR}/test_${x}.lua"
	)
	# param: executable file source files
	add_executable("test_${x}"
		"${test_SOURCE_DIR}/generated/test_${x}.cpp"
		"main.cpp"
		"../luna.cpp"
		"../luna.h"
		)
	if(UNIX)
		# param: executable file libraries. librt is necessary for profiler.
		target_link_libraries("test_${x}" ${LUA_LIBRARY} "rt" "dl")
	else()
		target_link_libraries("test_${x}" ${LUA_LIBRARY} )
	endif()

	if(UNIX)
	# execute built test routine -> removed because some tests require mylib.lua in the path.
	add_custom_command(
		TARGET "test_${x}"
		DEPENDS "${EXECUTABLE_OUTPUT_PATH}/test_${x}"
		POST_BUILD	
		COMMAND "${EXECUTABLE_OUTPUT_PATH}/test_${x}"
		)
	endif()
endfunction()

add_luna_test("simple")
add_luna_test("garbage_collection")
add_luna_test("var_arg")
add_luna_test("property")
add_luna_test("inheritance")
add_luna_test("operator_overloading")
add_luna_test("profiler")
add_luna_test("inheritance_from_lua")
#add_luna_test("table")


