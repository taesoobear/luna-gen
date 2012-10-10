gen_lua.use_profiler=true
function generate()
	writeIncludeBlock();
	write([[
	#include <cstddef>
	#include "assert.h"
	#include "test.hpp"

	struct Foo
	{
		static std::size_t count;

		Foo()
		{
			for (int i=0;  i<200000000; i++)
			++count;
		}

		~Foo()
		{
			--count;
		}

		void inc()
		{
			for (int i=0; i<1; i++)
				count++;
		}

		void incMultiple(int n)
		{
			for (int i=0; i<n ;i ++)
				inc();
		}
	};

	std::size_t Foo::count = 0;

	void register_foo(lua_State* L);
	void test_main(lua_State* L)
	{
		register_foo(L);

		FractionTimer::init();
		printf("test profiler started: this can take some time\n");
		luaL_dostring(L, "x = Foo()\n"); // C++ loops
		luaL_dostring(L, "for i=1,200000000 do i=i+1 end"); // lua loops
		FractionTimer::printSummary("test1", "C++", "lua");
		luaL_dostring(L, "x = Foo() for i=1,2000000 do x:inc() end\n"); // lua+cpp loops
		FractionTimer::printSummary("test2.0", "C++", "lua");
		luaL_dostring(L, "x = Foo() local inc=Foo.inc for i=1,2000000 do inc(x) end\n"); // lua+cpp loops
		FractionTimer::printSummary("test2.1", "C++", "lua");
		luaL_dostring(L, "do local x = Foo() local inc=Foo.inc for i=1,2000000 do inc(x) end end\n"); // lua+cpp loops
		FractionTimer::printSummary("test2.2", "C++", "lua");
		luaL_dostring(L, "do local x = Foo() x:incMultiple(2000000) end\n"); // cpp loops
		FractionTimer::printSummary("test2.3", "C++", "lua");
		luaL_dostring(L, "for i=1,200000000 do i=i+1 end"); // lua loops only
		FractionTimer::printSummary("test3", "C++", "lua");
		luaL_dostring(L, "x = Foo()\n"); // C++ loops only
		FractionTimer::printSummary("test4", "C++", "lua");
	}
	]])
 
	local bindTarget={
		classes={
			{
				name='Foo', --necessary
				ctors=  -- constructors 
				{
					'()'
				},
				memberFunctions={[[
				void inc();
				void incMultiple(int n);
				]]}
			},
		},
	}
	buildDefinitionDB(bindTarget)
	writeDefinitions(bindTarget, "register_foo")
	if gen_lua.output_file_name then
		flushWritten(input_filepath..'/generated/'..gen_lua.output_file_name)
	else
		flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
	end
end

