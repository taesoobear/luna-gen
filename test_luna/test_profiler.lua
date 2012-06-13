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
			for (int i=0;  i<100000000; i++)
			++count;
		}

		~Foo()
		{
			--count;
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
		luaL_dostring(L, "for i=1,100000000 do i=i+1 end"); // lua loops
		printf("test profiler finished: C++ %gms, lua %gms\n", FractionTimer::stopInside(), FractionTimer::stopOutside());
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
			},
		},
	}
	buildDefinitionDB(bindTarget)
	writeDefinitions(bindTarget, "register_foo")
	flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
end

