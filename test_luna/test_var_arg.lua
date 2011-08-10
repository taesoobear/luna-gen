
function generate()
	writeIncludeBlock();
	write([[
	#include <cstddef>
	#include "assert.h"
	#include "test.hpp"

	void register_foo(lua_State* L);
	struct Foo
	{
		Foo() { } 
		~Foo() { }
	};

	void test_main(lua_State* L)
	{
		register_foo(L);

		]])
		local luaCode=
		[[
		foo=Foo()
		foo:foo(1,2)
		foo:foo(1,2,3)
		foo:foo2({1,2,3},2)
		f(1,2,3,4)
		]]
		write([[printf("\n Input:\n");]])
		write([[printf("%s", ]]..luacodeInCquote(luaCode)..[[);]])
		write([[printf("\n Result:\n");]])
		write([[luaL_dostring(L, ]]..luacodeInCquote(luaCode)..[[);
		printf("test_var_arg finished\n");
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
				wrapperCode=
				[[
				static int foo(lua_State* L)
				{
					Foo& self=*luna_t::check(L,1);
					printf("foo: ");
					for (int i=2,n=lua_gettop(L); i<=n; i++)
					{
						assert(lua_isnumber(L,i)==1);
						printf("%d ", (int)lua_tonumber(L,i));
					}
					printf("\n");
				}
				static int foo2(lua_State* L)
				{
					Foo& self=*luna_t::check(L,1);
					luna_printStack(L);
					// read table
					int tblidx=2;
					assert(lua_istable(L,tblidx));

					//int ctop=lua_gettop(L); 
					for (int i=1;1; i++){
						lua_pushnumber(L,i); // top<=top+1
						lua_gettable(L,tblidx);   // index is replaced by table[index]
						//int newtop=ctop+1; // absolute index (newtop:4) works
						int newtop=-1; // relative index (top:-1) is more convenient
						printf("%dth gettable result:\n",i);
						luna_printStack(L,true);
						if (lua_isnil(L,newtop)==1) break;
						printf(" -> arg[2][%d]=%f\n", i, (float)lua_tonumber(L,newtop));
						lua_pop(L,1);// remove newtop
					}
					return 0;
				}
				]],
				custumFunctionsToRegister={'foo','foo2'},
			},
		},
		modules={ -- set of functions, listed by namespaces
			{
				namespace='_G', --necessary
				wrapperCode=
				[[
				static int f(lua_State* L)
				{
					printf("f: ");
					for (int i=1,n=lua_gettop(L); i<=n; i++)
					{
						assert(lua_isnumber(L,i)==1);
						printf("%d ", (int)lua_tonumber(L,i));
					}
					printf("\n");
				}
				]],
				custumFunctionsToRegister={'f'},
			},
		},
	}
	buildDefinitionDB(bindTarget)
	writeDefinitions(bindTarget, "register_foo")
	flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
end

