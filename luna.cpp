

#include "luna.h"
void luna_printStack(lua_State* L, bool compact)
{
	if(compact)
		printf("stack top:%d - ", lua_gettop(L)); 
	else
		printf("stack trace: top %d\n", lua_gettop(L)); 

	for(int ist=1; ist<=lua_gettop(L); ist++) {
		if(compact)
			printf("%d:%c",ist,luaL_typename(L,ist)[0]);
		else
			printf("%d:%s",ist,luaL_typename(L,ist));
		if(lua_isnumber(L,ist) ==1) {
			printf("=%f ",(float)lua_tonumber(L,ist));
		} else if(lua_isstring(L,ist) ==1){
			printf("=%s ",lua_tostring(L,ist));
		} else {
			printf(" ");
		}
		if( !compact)printf("\n");
	}
	printf("\n");
}
void luna_dostring(lua_State* L, const char* luacode)
{
	// luaL_dostring followed by pcall error checking 
	if (luaL_dostring(L, luacode)==1)
	{
		printf("Lua error: stack :\n");
		luna_printStack(L,false);
	}
}
lunaStack::~lunaStack()
{
}
