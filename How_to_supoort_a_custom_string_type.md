By defaults, gen\_lua automatically converts three string types (`const char*, std::string, TString`) into lua native string type.

Conversion rules for these three types are defined in luna\_gen.lua:
```
-- string types has to support static conversion  to const char*, and construction from const char*.
gen_lua.string_types={'const%s+char%s*%*', 'std%s*::%s*string', 'TString'} 
gen_lua.string_to_cstr={'@'              , '@.c_str()',         '@.ptr()'}
gen_lua.string_from_cstr={'@'            , 'std::string(@)',    'TString(@)'}
```
In an input script, you can register other string types as follows:
```
local N=#gen_lua.string_types+1
gen_lua.string_types[N]='QString'
gen_lua.string_to_cstr[N]='@.c_str()'
gen_lua.string_from_cstr[N]='QString(@)'
```
the **`string_types`** variable contains a list of regular expressions for parsing. The second variable **`string_to_cstr`** means that string variable **`std::string a`** can be converted to **`const char*`** using **`a.c_str()`**. **`string_from_cstr`** is the inverse.
Note that even when your program uses namespace such as `using namespace std`, you have to register funtions using the `std::string`.
```
   (X) void a(const string & a);
   (O) void a(const std::string& a);
```