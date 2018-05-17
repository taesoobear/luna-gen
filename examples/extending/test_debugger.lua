package.path=package.path..";../../?.lua"

require("mylib")
require("mathlib").register()
a=mathlib.vector3()
a.x=1
for i=1,1000 do
	a.x=a.x+1
end
print('a.x='..a.x)
print('mathlib: (0,1,2) +,- (3,4,2)')
print(mathlib.vector3(0,1,2)+mathlib.vector3(3,4,2))
print(mathlib.vector3(0,1,2)-mathlib.vector3(3,4,2))
print('mathlib: ==')
print(mathlib.vector3(0,1,2)==mathlib.vector3(0,1,2))
print(mathlib.vector3(0,1,2)==mathlib.vector3(0,1,4))
print('mathlib: ~=')
print(mathlib.vector3(0,1,2)~=mathlib.vector3(0,1,2))
print(mathlib.vector3(0,1,2)~=mathlib.vector3(0,1,4))
print('mathlib: (0,1,2) <, <=, >, >= (0,1,2)')
--package.path="../../?.lua;../../../?.lua;package.path" require('mylib') dbg.console()
print(mathlib.vector3(0,1,2)<mathlib.vector3(0,1,2))
print(mathlib.vector3(0,1,2)<=mathlib.vector3(0,1,2))
print(mathlib.vector3(0,1,2)>mathlib.vector3(0,1,2))
print(mathlib.vector3(0,1,2)>=mathlib.vector3(0,1,2))
print("mathlib overloading 1 finished\n");


print("Type help to see how to use the debugger.")
print("Type cont to finish the debugger!")
-- start a debugger
dbg.console()


function errorneous(arg1)
	error("some errorneous code", arg1)
end


-- use xpcall to invoke the debugger when an error occurs.
xpcall(errorneous, dbg.console, 1)

