
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

		luaL_dostring(L, "x = Foo()\n");
		TEST_CHECK(Foo::count==1);
		luaL_dostring(L, "x = nil\n");
		lua_gc(L, LUA_GCCOLLECT,0);
		TEST_CHECK(Foo::count==0);
		printf("test_gc finished\n");
	}
	]])

	local bindTarget={
		classes={
			-- table name LVectorn will be the class name in lua
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

