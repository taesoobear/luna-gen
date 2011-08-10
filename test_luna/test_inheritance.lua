bindTarget={
	classes={
		{
			name='ParentCPP',
			decl='class ParentCPP;', -- this goes into header file
			-- don't set inheritedFrom='luna_wrap_object' here
			-- Instead, use the following to enable inheritance from lua.
			isLuaInheritable=true, -- without this, this class cannot be inherited from lua. This exposes a member function new_modified_T .
			globalWrapperCode=[[  // this goes into cpp file
			std::list<ParentCPP*> g_obj;
			class ParentCPP : public luna_wrap_object {
				public:
				ParentCPP() 
				{
					g_obj.push_back(this);
					printf("parentCPP created\n");
				}
				~ParentCPP()
				{
					g_obj.remove(this);
					printf("parentCPP collected\n");
				}
				void foo()
				{
					printf("parentCPP foo\n");
				}
				int notify() // message passing between lua and c++ 
				{
					//printf("stack before notify() call: "); luna_printStack(_L,true);
					lunaStack l(_L);	
					// call void self:notified(10,100,1000)   where getmetatable(self)==__luna[_custumMT]
					if(pushMemberFunc<ParentCPP>(l,"notified")){
						// push input arguments = (self, 10, 100,1000)
						l<<10.0<<100.0<<1000.0;
						l.call(4,1); // numIn (inclusing self), numOut
						double out;
						l>>out;
						printf("cpp notified back: %f\n", out);
						//printf("stack after notify() call: "); luna_printStack(_L,true);
						return int(out);
					}
				else {
						printf("derived class doesn't have notified function\n");
						return -1;
					}
				}
			};
			]],
			ctors={'()'},
			memberFunctions={[[
				void foo()
			]]},
		}
	}
}
function generate()

	buildDefinitionDB(bindTarget)
	writeIncludeBlock();
	write([[
			#include <iostream>
			#include <stdio.h>
		  #include <list>
	  ]])
	-- usually, above contents goes into a header file, but here
	-- I put everything into a single cpp file for simplicity.
	writeDefinitions(bindTarget, "register_v")

	-- to fully understand the followings, just read the output cpp file (test_main function).
	local luaCode=[[
	Parent=LUAclass()
	function Parent:__init()
		print('parent created')
	end
	function Parent:foo()
		print('parent foo')
	end

	Child=LUAclass(Parent)
	function Child:__init()
		print('child created')
	end

	Child2=LUAclass(ParentCPP)
	function Child2:__init()
		print('child2 created')
	end
	function Child2:notified(x,y,z)
	 	print('child2 notified ',x,y,z, self.k)
	 	return 333
	end

	]]

	local luaCode2=[[
	do
		local a=Parent()
		local b=Child()
		b:foo()
		function Child:foo()
			print('child foo called')
		end
		b:foo()
		local c=ParentCPP()
		c.k=4
		c:foo()
	end
	 collectgarbage()
	print('Now testing "lua inherits cpp"\\n')
	d=Child2()
	d:foo()
	function Child2:foo()
		print('overrided child2 foo called\\n')
	end
	d:foo()
	d.k=3  
	print(d.k)
	]]
	write[[
	void test_main(lua_State* L)
	{
		register_v(L);
		]]
	write(codeRequireMylib()); -- function LUAclass is defined in mylib.lua. (TODO: embed into luna.h)
	write([[printf("\n Input:\n");]])
	write([[printf("%s\n", ]]..luacodeInCquote(luaCode)..');')
	write([[printf("\n Result:\n");]])
	write(codeDostring(luaCode))
	write(codeDostring(luaCode2))
	write([[
				  printf("Test message passing\n");
			std::list<ParentCPP*>::iterator i;
			  for (i=g_obj.begin();i!=g_obj.end(); ++i){
				  (*i)->notify();
			  }
	  ]])
	write("}")
	flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
end
-- implementation note:
-- internal type checking is done by "int uniqueID;" comparision. (Fast!)
-- all child class reuses parent's uniqueID.
-- all child's pointer is internally static-casted to the uppermost parent's type.
-- this doesn't mean metatable is shared among derived classes. 
-- (derived classes have independent metatable for overloading, etc)
-- lua class can inherit from c++ side.
-- (as long as the lua class is not inherited by another lua class.)
-- c++ side can inherit from lua class, but not as trivial.
-- (this can be implemented using lua call similar to the message passing shown above)
