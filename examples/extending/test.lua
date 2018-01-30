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
