if false then -- debug mode functions. (significant performance overhead when enabled.)
	ipairs_old=ipairs
	function ipairs(t,f)
		if t==nil then dbg.console('ipairs error') end
		return ipairs_old(t,f)
	end
end
-- collection of utility functions that depends only on standard LUA. (no dependency on baseLib or mainLib)
-- all functions are platform independent

function string.trimSpaces(s)
  s = string.gsub(s, '^%s+', '') --trim left spaces
  s = string.gsub(s, '%s+$', '') --trim right spaces
  return s
  end
  function string.startsWith(a,b)
	  return string.sub(a,1,string.len(b))==b
  end
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(string.trimSpaces(s), '[\n\r]+', ' ') 
  return s
end
function os.rightTokenize(str, sep, includeSep)
	--deprecated
	return string.rightTokenize(str, sep, includeSep)
end

function string.rightTokenize(str, sep, includeSep)
	local len=string.len(str)
	for i=len,1,-1 do
		local s=string.find(string.sub(str, i,i),sep)
		if s then
			if includeSep then
				return string.sub(str, 1, i-1)..sep, string.sub(str, i+1)
			end
			return string.sub(str, 1, i-1), string.sub(str, i+1)
		end
	end
	return "", str
end


function os.sleep(aa)
   local a=os.clock()
   while os.difftime(os.clock(),a)<aa do -- actually busy waits rather then sleeps
   end
end

function string.isLongestMatched(str, patterns, prefix, postfix)
	local matched=nil
	local ll=0
	for k,ip in ipairs(patterns) do
		if str==ip then return k end -- exact match has the highest priority
		if prefix then ip=prefix..ip end
		if postfix then ip=ip..postfix end
		local idx,idx2=string.find(str, ip)
		
		if idx~=nil then
			if idx2-idx>=ll then
				matched=k
				ll=idx2-idx
			end
		end
	end
	return matched
end

function string.isMatched(str, patterns)
	local matched=nil
	for k,ip in ipairs(patterns) do
		local idx=string.find(str, ip)
		if idx~=nil or str==ip then
			matched=k
		end
	end
	return matched
end
function string.findLastOf(str, pattern)
	local lastS=nil
	local idx=0
	while idx+1<#str do
		idx=string.find(str, pattern, idx+1)
		if idx then
			lastS=idx
		else
			break
		end
	end
	return lastS
end
function os.isUnix()  -- has posix commands
	local isWin=string.find(string.lower(os.getenv('OS') or 'nil'),'windows')~=nil
	if isWin then
		if string.find(string.lower(os.getenv('PATH') or 'nil'), ':/cygdrive') then
			return true
		end
		return false
	end
	return true
end

function os.isMsysgit()
	local isMsysgit=string.find(string.lower(os.getenv('PATH') or 'nil'), 'msysgit')~=nil
	return isMsysgit
end
function os.isWindows()
	local isWin=string.find(string.lower(os.getenv('OS') or 'nil'),'windows')~=nil
	return isWin
end


-- LUAclass method is for avoiding so many bugs in luabind's "class" method (especially garbage collection).

-- usage: MotionLoader=LUAclass()
--   ...  MotionLoader:__init(a,b,c)

--        VRMLloader=LUAclass(MotionLoader)
--   ...  VRMLloader:__init(a,b,c)
--              MotionLoader.__init(self,a,b,c)
--        end

--  loader=VRMLloader(a,b,c) 

function LUAclass(baseClass)

	local classobj={}
	classobj.__index=classobj
	classobj.new=function (classobj, ...)
		local new_inst={}
		setmetatable(new_inst, classobj)
		new_inst:__init(...)
		return new_inst
	end

	if baseClass~=nil then
		if baseClass.luna_class then
			local derivedName=baseClass.luna_class..'_derived'
			while __luna['_'..derivedName] do
				derivedName=derivedName..'_'
			end
			__luna['_'..derivedName]=classobj
			classobj.luna_class=derivedName
			if baseClass.new_modified_T==nil then
				print("Error!".. baseClass.luna_class.." doesn't have new_modified_T member!")
				print("Did you forget to set isLuaInheritable=true?")
			end
			for k,v in pairs(baseClass) do
				classobj[k]=v
			end

			classobj.new=function (classobj, ...)
							 local new_inst=classobj.new_modified_T(classobj, '_'..derivedName) -- has to have default constructor. 
							 new_inst:__init(...)
							 return new_inst
						 end
		end
		setmetatable(classobj, {__index=baseClass,__call=classobj.new})
	else
		setmetatable(classobj, {__call=classobj.new})
	end
	return classobj
end

function LUAclass_getProperty(t, nocheck)
	local result={}
	if type(t)=="userdata" then
		result=t:toTable() -- {"__userdata", typeName, type_specific_information...}
	elseif type(t)=='table' and getmetatable(t) and t.toTable and not nocheck then
		result=t:toTable()
	elseif type(t)=="table" then
		for k, v in pairs(t) do
			if k=="__index" then
				-- do nothing
			elseif k=="__newindex" then
				-- do nothing
			elseif type(v)=="function" then
				-- do nothing
			elseif type(v)=="table" or type(v)=="userdata" then
				result[k]=LUAclass_getProperty(v)
			else
				result[k]=v
			end
		end
	else
		result=t
	end
	return result
end
function LUAclass_setProperty(result, t)
	for k, v in pairs(t) do
		if type(v)=='table' and v[1]=="__userdata" then
			result[k]=_G[v[2]].fromTable(v)
		elseif type(v)=='table' then
			assert(result[k] and type(result[k])=='table')
			LUAclass_setProperty(result[k], v)
		else
			result[k]=v
		end
	end
end
-- one indexing. 100% compatible with original lua table. (an instance is an empty table having a metatable.)
array=LUAclass()

--[[
    zip_with_helper ()

    This is a generalized version of Haskells zipWith, but instead
    of running a function and appending that result to the list of results
    returned, we call a helper function instead.

    So this function does most of the work for map(), filter(), and zip().

    result_helper may do a variety of things with the function to
    be called and the arguments.  The results, if any, are appended
    to the resutls_l table.
]]--
local function zip_with_helper(result_helper, rh_arg, ...)
     local results_l= {}
     local args = {...}     -- a table of the argument lists
     local args_pos = 1     -- position on each of the individual argument lists
     local have_args = true

     while have_args do
        local arg_list = {}
        for i, v in ipairs(args) do
            local a = nil
            a = v[args_pos]
            if a then
                arg_list[i] = a
            else
                have_args = false
                break
            end
        end
        if have_args then
            result_helper(rh_arg, arg_list, results_l)
        end
        args_pos = args_pos + 1
    end
                    
     return results_l
end

 --[[
    filter(func, [one or more tables])

    Selects the items from the argument list(s), calls
    func() on that, and if the result is true, the arguments
    are appended to the results list.

    Note that if func() takes only one argument and one
    list of arguments is given, the result will be a table
    that contains the values from the argument list directly.

    If there are two or more argument lists, then the 
    result table will contain a list of lists of arguments that matched
    the condition implemented by func().

    Examples:
        function is_equal (x, y) return x == y end
        function is_even (x) return x % 2 == 0 end
        function is_less (x, y) return x < y end


        filter(is_even, {1,2,3,4}) -> {2,4}

        filter(is_equal, {10, 22, 30, 44, 40}, {10, 20, 30, 40})   --> {{10,10}, {30, 30}}

        filter(is_less, {10, 20, 30, 40}, {10, 22, 33, 40})        --> {{20,22}, {30, 33}}

 ]]--
local function filter_helper (func, arg_list, results_l)
    local result = func(unpack(arg_list))
    if result then
        if #arg_list == 1 then
            table.insert(results_l, arg_list[1])
        else
            table.insert(results_l, arg_list)
        end
    end
end

function array.filter(func, ...)
    return zip_with_helper(filter_helper, func, ...)
end

 --[[
    map(function, [one or more tables])

    Repeatedly apply the function to the arguments composed from the
    elements of the lists provided.

    Examples:
        function double(x) return x * 2 end
        function add(x,y) return x + y end

        map(double, {1,2,3})                -> {2,4,6}
        map(add, {1,2,3}, {10, 20, 30})     -> {11, 22, 33}

    This also implements the functionality of 
        zipWith, zipWith3, zipWith4, etc. 
    in Haskell.

    func() should be a function that takes as many
    arguments as tables provided.  map() returns a list of just the
    first return values from each call to func().
 ]]--
local function map_helper (func, arg_list, results_l)
    table.insert(results_l, func(unpack(arg_list)))
end

function array.map(func, ...)
    return zip_with_helper(map_helper, func, ...)
end
 --[[
    foldr() - list fold right, with initial value

    foldr(function, default_value, table)

    Example:
        function mul(x, y) return x * y end
        function div(x, y) return x / y end

        foldr(mul, 1, {1,2,3,4,5})  ->  120
        foldr(div, 2, {35, 15, 6})  ->  7
 ]]--
function array.foldr(func, val, tbl)
    for i = #tbl, 1, -1 do
        val = func(tbl[i], val)
    end
    return val
end
function array:__init()
end
function array:clear()
	self={}
	setmetatable(self,array)
end

function array:size()
	return table.getn(self)
end

function array:pushBack(...)
	assert(self)
	for i, x in ipairs({...}) do
		table.insert(self, x)
	end
end

function array:popFront()
	local out=self[1]
	for i=1,#self-1 do
		self[i]=self[i+1]
	end
	self[#self]=nil
	return out
end

function array:pushBackIfNotExist(a)
	for i, v in ipairs(self) do
		if self[i]==a then
			return 
		end
	end
	array.pushBack(self, a)
end

function array:concat(tbl)
	for i, v in ipairs(tbl) do 
		table.insert(self, v)
	end
end

-- input : tables
function array.concatMulti(...)
	local out={}
	for i,v in ipairs({...}) do
		assert(type(v)=='table')
		array.concat(out,v)
	end
	return  out
end


function array:removeAt(i)
	table.remove(self, i)
end


function array:assign(tbl)
   for i=1,table.getn(tbl) do
      self[i]=tbl[i]
   end
end
function array:remove(...)
   local candi={...}
   if type(candi[1])=='table' then
      candi=candi[1]
   end

   local backup=array:new()
   for i=1,table.getn(self) do
      backup[i]={self[i], true}
   end
   
   for i, v in ipairs(candi) do
      backup[v][2]=false
   end

   local count=1
   for i=1, table.getn(backup) do
      if backup[i][2] then
	 self[count]=backup[i][1]
	 count=count+1
      end
   end

   for i=count, table.getn(backup) do
      self[i]=nil
   end

end

function array:back()
	return self[table.getn(self)]
end

function string.join(tbl, sep)
	return table.concat(tbl, sep)
end

function string.isOneOf(str, ...)
	local tbl={...}
	for i,v in ipairs(tbl) do
		if str==v then
			return true
		end
	end
	return false
end

-- similar to string.sub
function table.isubset(tbl, first, last)

	if last==nil then last=table.getn(tbl) end
	if last<0 then last=table.getn(tbl)+last+1 end

	local out={}
	for i=first,last do
		out[i-first+1]=tbl[i]
	end
	return out
end

function table.find(tbl, x)
	for k, v in pairs(tbl) do
		if v==x then 
			return k
		end
	end
	return nil
end
function table.filter(fcn, tbl)
	local out={}
	for k,v in pairs(tbl) do
		if fcn(k,v) then
			out[k]=v
		end
	end
	return out
end
function table.filterByKey(pattern, tbl)
	local out={}
	for k,v in pairs(tbl) do
		if select(1,string.find(k,pattern) ) then
			out[k]=v
		end
	end
	return out
end

function table._ijoin(tbl1, tbl2)
	local out={}
	local n1=table.getn(tbl1)
	local n2=table.getn(tbl2)
	for i=1,n1 do
		out[i]=tbl1[i]
	end

	for i=1,n2 do
		out[i+n1]=tbl2[i]
	end
	return out
end

function table.ijoin(...)
	local input={...}
	local out={}
	for itbl, tbl in ipairs(input) do
		out=table._ijoin(out, tbl)
	end
	return out
end

function table.join(...)
	local input={...}
	local out={}
	for itbl, tbl in ipairs(input) do
		for k,v in pairs(tbl) do
			out[k]=v
		end
	end
	return out
end

function table.mult(tbl, b)

	local out={}
	for k,v in pairs(tbl) do
		out[k]=v*b
	end
	setmetatable(out,table)
	return out
end


function table.add(tbl1, tbl2)

	local out={}

	for k,v in pairs(tbl1) do
		if tbl2[k] then
			out[k]=tbl1[k]+tbl2[k]
		end
	end
	for k,v in pairs(tbl2) do
		if tbl1[k] then
			out[k]=tbl1[k]+tbl2[k]
		end
	end
	setmetatable(out,table)

	return out
end
table.__mul=table.mult
table.__add=table.add

function pairsByKeys (t, f)
   local a = {}
   for n in pairs(t) do table.insert(a, n) end
   if f==nil then
	   f=function (a,b) -- default key comparison function
		   if type(a)==type(b) then
			   return a<b
		   end
		   return type(a)<type(b)
	   end
   end
   table.sort(a, f)
   local i = 0      -- iterator variable
   local iter = function ()   -- iterator function
		   i = i + 1
		   if a[i] == nil then return nil
		   else return a[i], t[a[i]]
		   end
		end
   return iter
end

function printTable(t, bPrintUserData)
	local out="{"
	for k,v in pairsByKeys(t) do
		local tv=type(v)
		if tv=="string" or tv=="number" or tv=="boolean" then
			out=out..'['..k..']='..tostring(v)..', '
		elseif tv=="userdata" then
			if bPrintUserData==true then
				out=out..'\n['..k..']=\n'..v..', '
			else
				out=out..'['..k..']='..tv..', '
			end
		else
			out=out..'['..k..']='..tv..', '
		end
	end
	print(out..'}')
end


function table.fromstring(t_str)
	local fn=loadstring("return "..t_str)
	if fn then
		local succ,msg=pcall(fn)
		if succ then
			return msg
		else
			print('pcall failed! '..t_str..","..msg)
		end
	else
		print('compile error')
	end
	return nil
end

function table.tostring2(t)
	return table.tostring(util.convertToLuaNativeTable(t))
end
function table.fromstring2(t)
	return util.convertFromLuaNativeTable(table.fromstring(t))
end
function table.toHumanReadableString(t, spc)
	spc=spc or 4
	-- does not check reference. so infinite loop can occur.  to prevent
	-- such cases, use pickle() or util.saveTable() But compared to pickle,
	-- the output of table.tostring is much more human readable.  if the
	-- table contains userdata, use table.tostring2, fromstring2 though it's
	-- slower.  (it preprocess the input using
	-- util.convertToLuaNativeTable 
	-- a=table.tostring(util.convertToLuaNativeTable(t)) convert to
	-- string t=util.convertFromLuaNativeTable(table.fromstring(a)) 
	-- convert back from the string)

	local out="{"

	local N=table.getn(t)
	local function packValue(v)
		local tv=type(v)
		if tv=="number" or tv=="boolean" then
			return tostring(v)
		elseif tv=="string" then
			return '"'..tostring(v)..'"'
		elseif tv=="table" then
			return table.toHumanReadableString(v,spc+4)
		end
	end

	for i,v in ipairs(t) do
		out=out..packValue(v)..", "
	end

	for k,v in pairsByKeys(t) do

		local tk=type(k)
		local str_k
		if tk=="string" then
			str_k="['"..k.."']="
			out=out..string.rep(' ',spc)..str_k..packValue(v)..',\n '
		elseif tk~="number" or k>N then	 
			str_k='['..k..']='
			out=out..string.rep(' ',spc)..str_k..packValue(v)..',\n '
		end
	end
	return out..'}\n'
end
function table.tostring(t)
	-- does not check reference. so infinite loop can occur.  to prevent
	-- such cases, use pickle() or util.saveTable() But compared to pickle,
	-- the output of table.tostring is much more human readable.  if the
	-- table contains userdata, use table.tostring2, fromstring2 though it's
	-- slower.  (it preprocess the input using
	-- util.convertToLuaNativeTable 
	-- a=table.tostring(util.convertToLuaNativeTable(t)) convert to
	-- string t=util.convertFromLuaNativeTable(table.fromstring(a)) 
	-- convert back from the string)

	local out="{"

	local N=table.getn(t)
	local function packValue(v)
		local tv=type(v)
		if tv=="number" or tv=="boolean" then
			return tostring(v)
		elseif tv=="string" then
			return '"'..tostring(v)..'"'
		elseif tv=="table" then
			return table.tostring(v)
		else 
			return tostring(v)
		end
	end

	for i,v in ipairs(t) do
		out=out..packValue(v)..", "
	end

	for k,v in pairs(t) do

		local tk=type(k)
		local str_k
		if tk=="string" then
			str_k="['"..k.."']="
			out=out..str_k..packValue(v)..', '
		elseif tk~="number" or k>N then	 
			str_k='['..k..']='
			out=out..str_k..packValue(v)..', '
		end
	end
	return out..'}'
end
function table.remove_if(table, func)
	for k,v in pairs(table) do
		if func(k,v) then
			table[k]=nil
		end
	end
end
util=util or {}

function util.chooseFirstNonNil(a,b,c)
	if a~=nil then return a end
	if b~=nil then return b end
	return c
end
function util.convertToLuaNativeTable(t)
	local result={}
	if type(t)=="userdata" then
		result=t:toTable() -- {"__userdata", typeName, type_specific_information...}
	elseif type(t)=='table' and getmetatable(t) and t.toTable then
		result=t:toTable()
	elseif type(t)=="table" then
		for k, v in pairs(t) do
			if type(v)=="table" or type(v)=="userdata" then
				result[k]=util.convertToLuaNativeTable(v)
			else
				result[k]=v
			end
		end
	else
		result=t
	end
	return result
end

function util.convertFromLuaNativeTable(t)
	local result
	if type(t)=="table" then
		if t[1]=="__userdata" then
			result=_G[t[2]].fromTable(t)
		else
			result={}
			for k, v in pairs(t) do
				result[k]=util.convertFromLuaNativeTable(v)
			end
		end
	else
		result=t
	end

	return result
end

function util.readFile(fn)
	local fout, msg=io.open(fn, "r")
	if fout==nil then
		print(msg)
		return
	end

	contents=fout:read("*a")
	fout:close()
	return contents
end

function util.iterateFile(fn, printFunc)
	printFunc=printFunc or
	{
		iterate=function (self,lineno, line) 
			print(lineno, line)
		end
	}
	local fin, msg=io.open(fn, "r")
	if fin==nil then
		print(msg)
		return
	end
	local ln=1
	--local c=0
	--local lastFn, lastLn
	for line in fin:lines() do
		printFunc:iterate(ln,line)
		ln=ln+1
	end
	fin:close()
end


function util.writeFile(fn, contents)
	local fout, msg=io.open(fn, "w")
	if fout==nil then
		print(msg)
		return
	end

	fout:write(contents)
	fout:close()
end
function util.appendFile(fn, arg)
	local fout, msg=io.open(fn, "a")
	if fout==nil then
		print(msg)
		return
	end
	fout:write(arg)
	fout:close()   
end

util.outputToFileShort=util.appendFile
function util.mergeStringShort(arg)
	local out=""
	for i,v in ipairs(arg) do
		local t=type(v)
		if t=='number' then
			out=out.."\t"..string.format("%.2f",v)
		elseif t~="string" then
			out=out.."\t"..tostring(v)
		else
			out=out.."\t"..v
		end
	end
	return out
end

function util.mergeString(arg)
	local out=""
	for i,v in ipairs(arg) do
		if type(t)~="string" then
			out=out.."\t"..tostring(v)
		else
			out=out.."\t"..v
		end
	end
	return out
end

function string.lines(str)
	assert(type(str)=='string')
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

function string.tokenize(str, pattern)
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)"..pattern, helper)))
	return t
end

function string.tokenize2(str, pattern, sep)
	local t = {}
	local function helper(line) if line~="" then table.insert(t, line) end table.insert(t, sep) return "" end
	helper((str:gsub("(.-)"..pattern, helper)))
	table.remove(t, #t)
	return t
end

function string.trimLeft(str)
	a=string.find(str, '[^%s]')
	if a==nil then
		return ""
	end
	return string.sub(str, a)
end
function string.trimRight(str)
	--a=string.find(str, '[%s$]')-- doesn't work
	a=string.find(str, '[%s]',#str)
	if a==nil then return str end
	return string.trimRight(string.sub(str,1,a-1))
end

function deepCopyTable(t)
	assert(type(t)=="table", "You must specify a table to copy")

	local result={}
	for k, v in pairs(t) do
		if type(v)=="table" then
			result[k]=deepCopyTable(v)
		elseif type(v)=="userdata" then
			if v.copy then
				result[k]=v:copy()
			else
				print('Cannot copy '..k)
			end
		else
			result[k]=v
		end
	end

	-- copy the metatable, if there is one
	return setmetatable(result, getmetatable(t))
end

function util.copy(b) -- deep copy
	if type(b)=='table' then
		local result={}
		for k,v in pairs(b) do
			result[k]=util.copy(v)
		end
		-- copy the metatable, if there is one
		return setmetatable(result, getmetatable(b))
	elseif type(b)=='userdata' then
		return b:copy()
	else
		return b
	end
end


function shallowCopyTable(t)
	assert(type(t)=="table", "You must specify a table to copy")

	local result={}

	for k, v in pairs(t) do
		result[k]=v
	end

	-- copy the metatable, if there is one
	return setmetatable(result, getmetatable(t))
end

function table.count(a)
	local count=0
	for k,v in pairs(a) do
		count=count+1
	end
	return count
end

-- t1 and t2 will be shallow copied. you can deepCopy using deepCopy(table.merge(...))
function table.merge(t1, t2)
	local result={}
	assert(type(t1)=='table' and type(t2)=='table')
	for k,v in pairs(t1) do
		result[k]=v
	end
	for k,v in pairs(t2) do
		if result[k] and type(result[k])=='table' and type(v)=='table' then
			result[k]=table.merge(result[k],v)
		else
			result[k]=v
		end
	end
	return result
end

-- note that t2 will be deep copied because it seems to be more useful (and safe)
function table.mergeInPlace(t1,t2, overwrite) -- t1=merge(t1,t2)
	for k,v in pairs(t2) do
		if overwrite or t1[k]==nil then
			t1[k]=util.copy(v)
		end
	end	
end

dbg={defaultLinecolor="solidred", linecolor="solidred", _count=1}


function os.print(t)
   if type(t)=="table" then
      printTable(t)
   else
      dbg.print(t)
   end
end

function dbg.print(...)
	local arr={...}
	for k,v in ipairs(arr) do
		if type(v)=='userdata' then
			if getmetatable(v).__luabind_class then
				local info=class_info(v)
				if info.methods.__tostring then
					print(v)
				else
					print('userdata which has no __tostring implemented:')
					util.printInfo(v)
				end
			else
				if getmetatable(v).__tostring then
					print(v)
				else
					print('userdata which has no __tostring implemented:')
					printTable(getmetatable(v))
				end
			end
		else
			print(v)
		end
	end
end
require('mylib_debugger')
require('mylib_filesystem')
