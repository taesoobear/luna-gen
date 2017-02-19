
require('mylib') -- to use 'LUAclass()' and 'dbg.console()' functions.

function main()
	print("type help or c to see how to use the debug console.")
	print("try typing lua sentences below. e.g.\n   a=vector3(3,4,5)\n   b=a+a\n   b")
	dbg.console() -- start the debug console. 
end

vector3=LUAclass()
function vector3:__init(x,y,z)
	self.x=x or 0
	self.y=y or 0
	self.z=z or 0
end

function vector3:__tostring()
   local out="vector3("
   out= out .. self.x ..", "..self.y..", "..self.z ..')'
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

main()
