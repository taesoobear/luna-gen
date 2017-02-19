-- this file contains an example of a cpp class (vector3) derived from a lua class (vector3).
-- see test_operator_overloading.lua and test_inheritance.lua also.
luaCode=[[
package.path=package.path..";../?.lua;../../?.lua;../../../?.lua"
require('mylib') -- to use 'LUAclass' function.

vector3=LUAclass()
function vector3:__init(x,y,z)
	self.x=x or 0
	self.y=y or 0
	self.z=z or 0
end

function vector3:__tostring()
   local out="vector3("
   out= out .. self.x ..", "..self.y..", "..self.z..")"
   return out
end

function vector3:assign(v)
	self.x=v.x
	self.y=v.y
	self.z=v.z
end

function vector3:copy()
	return vector3(self.x, self.y, self.z)
end

function vector3:__add(b)
	return vector3(self.x+b.x, self.y+b.y, self.z+b.z)
end

function vector3:__sub(b)
	return vector3(self.x-b.x, self.y-b.y, self.z-b.z)
end
function vector3:set(x,y,z)
	self.x=x
	self.y=y
	self.z=z
end

function vector3:zero()
	self.x=0
	self.y=0
	self.z=0
end

function vector3:length()
	return math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z)
end
]]

cppCode=[[
#include "luna.h"

class vector3 : public luna_derived_object
{
	public :

	vector3(lua_State* L, int uid):luna_derived_object(L, uid){}
	vector3(lua_State* L, double x, double y, double z):luna_derived_object(L)
	{
		// create new vector3 object in lua.
		_l.getglobal("vector3");
		_l<<x<<y<<z;
		call_ctor(3);
	}

	vector3 operator+(vector3 const& o)
	{
		pushMemberAndSelf("__add");
		push(o);
		_l.call(2,1); // out=__add(self, other)
		return vector3(_l.L, _storeNewObject()); // _storeNewObject clears the stack.
	}
	double getX(){
		//_l.printStack();
		pushSelf();
		_l.replaceTop("x");
		double x=_l.tonumber(-1);
		_l.pop();
		return  x;
	}
	double length(){
		// used beginCall/endCall instead of "call" just to show various examples. see luna.h for more comments!
		pushMemberAndSelf("length");
		int numOut=_l.beginCall(1); // out=length(self)
		if(numOut!=1) printf("???");
		double len;
		_l>>len;
		_l.endCall(numOut); // clears the stack
		return len;
	}
	void zero(){
		pushMemberAndSelf("zero");
		_l.call(1,0);   // vector3.zero(self)
	}
};

#include "test.hpp"
void test_main(lua_State* L)
{
	luaL_dostring(L, "if not __luna then __luna={} end");  // This manual creation is necessary because this example does not use any luna-gen-generated functions at all.
	luaL_dostring(L, ]]..luacodeInCquote(luaCode)..[[);
	vector3 a(L, 10,20,30);
	vector3 b(L, 40,0,0);
	TEST_CHECK((a+b).getX()==50);
	//luaL_dostring(L, "dbg.console()");
	TEST_CHECK( b.length()>39.99 && b.length()<40.01);
	a.zero();
	TEST_CHECK( a.length()==0);
	printf("test inheritnce_from_lua\n");
}
]]
function generate()
	-- no binding code is necessary because we are calling only lua functions from cpp. 
	writeIncludeBlock();
	write(cppCode);
	flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
end
