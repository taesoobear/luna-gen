
#include "../../luna.h"

void register_mathlib(lua_State*L);
extern "C"
{
static int registerMainLib(lua_State* L)
{
	register_mathlib(L);
}

static const struct luaL_reg lib[] = {
	{"register", registerMainLib},
	{NULL, NULL},
};
int luaopen_mathlib(lua_State*L)
{
	luaL_openlib (L, "mathlib", lib, 0);
	return 1;
}
}
