luna-gen
========

lua binding code generator that supports nearly all the functionalities of famous existing alternatives such as luabind and tolua++.

-    lua/c++ bi-directional function calls and value setting/getting.
-    member properties (such as "a.x =3" )
-    inheritance (both from lua and c++)
-    namespace (both c++ namespaces such as std::vector and lua tables such as string.strcmp)
-    enum
-    type-checking (can be turned off)
-    c++ exception handling (can be turned off)
-    adopt-policy, discard_result
-    supports both g++ and MSVS
-    function overloading (e.g. void add(int a,int b); void add(int a, int b, int c);)
-    operator overloading (e.g. double operator+(double a);)
-    user-configurable custom string and number/enum types
-    table manipulations (see test_table sample for details)
-    macro dependent binding definitions (ifdef/ifndef/if)
-    ... 

These functionalities have been well-tested on multiple research projects that I am involved.

Advantages over alternatives
========
-    It's about three times faster than luabind 9.1 (benchmarked in ubuntu linux.)
-    As fast as the best hand-written codes to my knowledge.
-    Output C++ codes are human-readable and thus are easy to debug.
-    Minimul use of template-programming for faster compilation speed.
-    Much more flexible than tolua++ because of the use of lua scripting language for input file format.
-    Written in native lua.
-    Include a good debugger. (dbg.console() - type h for help. lua test_debug_console.lua. Read examples/README also.)
-    Easy to use. See an example below and the samples in the test_luna folder (especially test_simple.lua).
-    Blend very well with native Lua API calls.
-    No C++ RTTI (run-time type information) used.
-    No boost dependency. Output codes depend only on luna.h/luna.cpp and liblua.
-    the built-in profiler to measure how much time is used in lua and C++, respectively. (enabled only when gen_lua.use_profiler is set true) 

Example
===

**input.lua**

	bindTarget={
	  classes={
	   {
		 name='math.NonuniformSpline', -- lua name
		 className='NonuniformSpline', -- an optional c++ name. 
     decl='class NonuniformSpline;', -- will be used in the generated header files.
     headerFile='NonuniformSpline.h', -- will be #included in the generated cpp files only.
		 ctors={'(vectorn const&, const matrixn&)', '()'}, -- constructors
		 memberFunctions={[[
		   void getCurve(vectorn const& time, matrixn& points);
		   void getFirstDeriv(vectorn const& time, matrixn& points);
		   void getSecondDeriv(vectorn const& time, matrixn& points);
		 ]]}
	   },
	   {
		 name='boolN',
		 ctors={'()','(int n)'},
		 -- any C++ code to include 
		 wrapperCode=[[
		  static boolNView _range(boolN const& a, int start, int end)
		  { return boolNView (a._vec, a._start+start, a._start+end);  }
		 ]],
		 -- to register non-member functions as member
		 staticMemberFunctions={[[                                                                             
		  boolNView _range(boolN const& a, int start, int end) @ range
							  ]]},
		 memberFunctions={[[
			 bitvectorn bit() const
			 void assign(const boolN& other)
			 void assign(const boolN& other)
			 void set(int i, bool b)
			 void setAllValue(bool b)
			 virtual void resize(int n)
			 int size();
			 TString output() @ __tostring
			 bool operator[](int i) @ __call
		  ]]}
		},
		modules={
		   { name='string',
			 functions={[[
				  int strcmp(const char* a, const char* b); // string.strcmp in lua
			 ]]}
		   },
		   { name='_G',
			 functions={[[
				  int strcmp(const char* a, const char* b); // strcmp in lua
			 ]]}
		   }
		 }
	}
	dofile('other_input.lua') -- assume this file contains a table bindTarget2
	function generate() 
	  buildDefinitionDB(bindTarget, bindTarget2) -- input contain all classes to be exported.
	  -- bind code can be split into multiple .h, .cpp files for simplifying dependencies
	  -- write the first header file (that exposes classes in table bindTarget)
	  write([[
					  class boolNView;
					  class boolN;
					  //class NonuniformSpline; // unnecessary, because of 'decl="class NonuniformSpline;" above'
	  ]])
	  writeHeader(bindTarget) 
	  flushWritten('bind.h')
	  -- header file doesn't contain #include at all. Forward declarations are all it needs.
	  -- write a cpp file
	  writeIncludeBlock() -- luna.h and such
	  write('#include "bind.h"') 
	  write([[
		#include "stdafx.h"
		#include "boolN.h"
		//#include "NonuniformSpline.h" // unnecessary because of headerFile='NonuniformSpline.h'
	  ]])
	  writeDefinitions(bindTarget, 'Register_bind') -- input can be non-overlapping subset of entire bindTarget 
	  flushWritten('bind.cpp') 
	  writeIncludeBlock() 
	  writeHeader(bindTarget2) -- bind declarations can directly go into bind2.cpp
	  writeDefinitions(bindTarget2, 'Register_bind2')  
	  flushWritten('bind2.cpp')
	end

Usage
=
   lua luna_gen.lua input.lua

Parser restrictions
=
 - Default parameters are supported by function overloading.


  >  (x) memberFunctions=[[ int add(int a, int b=0);]]   
 
  >  (O) memberFunctions=[[ int add(int a, int b);  
                             int add(int a);]]
                             
 - A member function definition should be in a single line

 >   (O) memberFunctions=[[ int add(int a, int b) ]]   
 
 >   (X) memberFunctions=[[ int add(int a,   
                               int b) ]]

 - Do not include function body in the input lua file.

 >   (X) memberFunctions={ 'int add(int a, int b) { return a+b;}' }
 
 >   (O) memberFunctions={ 'int add(int a, int b)' }
 
 >   (O) memberFunctions={ 'int add(int a, int b); // add a and b' }

 - Do not input or return pointer/reference to numbers because lua native types are treated as values (as opposed to references)

 >    (X) memberFunctions={ 'int* add(int &a)'}
 
 >    (O) memberFunctions={ 'int add(int a)'}

 - So if you want to export 'int* MyClass::add(int &a)', write a wrapper code such as

 > wrapperCode=[[ static int add2(MyClass & self, int a) { return *(self.add(a));}]],  
          staticMemberFunctions={[[   
               static int add2(MyClass& self, int a) @ add   
          ]]} -- "add2" is renamed to "add" in lua   

how to download, and run test programs
=
type

	git clone https://code.google.com/p/luna-gen/ 

in a terminal (or msysgit console on a windows machine.)

To compile:

On unix, after installing lua dependencies (for instance, sudo apt-get install liblua5.1-0-dev cmake)

	cd luna-gen/test_luna
	sh make.sh

On windows (assuming you are using msysgit console)

	cd luna-gen/test_luna
	mkdir build_win
	cd build_win
	cmake -G "Visual Studio 8 2005" ..

The target name differs depending on the MSVS compiler version. Build the resulting .sln file.

To update to the latest version,

	git pull origin master

Open source projects that use luna-gen

    paperCrop 

Missing features compared to luabind

    smart pointer integration
    ignores const modifiers
    no multiple inheritance (there can be only one super class - this is not a problem because you can always re-declare member functions of parent classes in a bind definition file.)
    type-error-checking less strict than luabind for classes derived from the same super-class (because luna-gen internally uses integer hash-codes instead of class names.)
    no automatic dependency of properties (a buggy example: local B do local A=CPPclass() B=A.x end B:doSomething() --can cause segmentation faults or memory problems because A in the inner block is freed before A.x:doSomething() is executed.) 

These missing features can lead to ungraceful errors if program is buggy. (for example, a buggy lua code which would have caused compilation error if it were a C++ code with line-by-line correspondance.)

These missing features are due to design decisions made to keep the binding code as FAST as possible. So these features won't be supported in the later versions either. (I think that the current version is feature-complete for most use-cases.)

Compatibility
=
Only luajit or lua5.1 are fully supported. 
(Many functionalities will still work for lua 5.2, but some won't.

I do not plan to support lua 5.2 or later because of the too many interface-breaking changes happening in the lua language.)

luna-gen works perfectly with Torch (the luajit-based deep learning library) too - see examples/extending for creating a shared library that can be required from Torch7. 

License
=
The code generator luna-gen.lua is under GPL-license, but its input/output files and the dependencies luna.h, luna.cpp, mylib.lua are NOT. (The dependencies are distributed under MIT license). So you can use luna-gen freely for all purposes including developing commercial apps without having to publish your source codes.)

Please ask questions using the issue tracker here or e-mails.

Notes
=
Recommend editor : vim (vim's auto-indenting works better than many other editors for luna-gen's definition files

Files 
=====
	test_luna/*.lua : self-contained examples (run make.sh to run) 
			These examples use CMake. If you don't want to use CMake, see "examples/gen.sh". 
      Use make.bat in windows.

	luna_gen.lua:  the code generator. 

	mylib*.lua: the code generator depends on these files, but output codes do not.
			luna.h/cpp: the output code depends only on these files. 
			luna.h is worth reading. (especially the lunaStack class is well-documented).

	examples/*.lua : real-world examples that use all available functionalities (run gen.sh to convert.)
				   The real-world examples do not run on your system because of missing dependencies.
	
	see examples/README for details. This file explains how to call a lua function from c.

Supported types
=============
	class   ( corresponds to a userdata that has a metatable )
	module  ( corresponds to a namespace in cpp and a table in lua. Multiple modules can have the same name. )

Supported class properties
======================
	name
	className
	inheritsFrom
	ctors
	wrapperCode : custom function definitions (any valid c++ code which goes into the output cpp file.)
	decl : custom class declarations (any valid c++ code which goes into the output header file)
	globalWrapperCode :custom function definitions (any valid c++ code which goes into the output cpp file.)
	ifdef
	ifndef
	if_
	isLuaInheritable
	enums
	staticMemberFunctions
	memberFunctionsFromFile
	memberFunctions
	isExtendableFromLua : for c++ inheritance from lua. See test_inheritance.lua
	properties 
	read_properties
	write_properties
	customFunctionsToRegister : luna-gen can register a custom function 'int funcName(lua_State* L)'

	Search for keyword in examples to see its usage, or ask me so that I can update this document. 

Notes for luabind users
===================

>- **luabind:**
		luabind::def("createVRMLskin", &RE::createVRMLskin,luabind::adopt(luabind::result))
- **luna-gen:**
		PLDPrimVRML* RE::createVRMLskin(VRMLloader*pTgtSkel, bool bDrawSkeleton) @ ;adopt=true; 

----------
>- **luabind:**
		.enum_("constants")
		[
			luabind::value("EULER",OpenHRP::DynamicsSimulator::EULER)
		]
- **luna-gen:**
	enums={
	{"EULER", "(int)OpenHRP::DynamicsSimulator::EULER"}, 
	}

----------
>- **luabind:**
		.scope_[..] 
- **luna-gen:**
        staticMemberFunctions={[[..]]}

----------

>- **luabind:**
		#ifndef AAA
			luabind::def("abc"...)
		#endif
- **luna-gen:**
		void abc() @ ;ifndef=AAA;

---------- 
>- **luabind:**
		#ifndef AAA
		    luabind::class_<asdf>("asdf")[...]
		#endif
- **luna-gen:**
       {
		   name='asdf',
		   ifndef='AAA',
	   }
		   


taesoobear@gmail.com


