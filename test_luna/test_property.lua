
function generate()
	writeIncludeBlock(true) -- property implementation uses hash_map implementation
	write([[

	#include <math.h>
	typedef double m_real;

	class vector3
	{
		public:

		m_real x, y, z;

		// constructors
		vector3() {}
		vector3( m_real v)				{ x=v; y=v; z=v;}
		vector3( m_real xx, m_real yy, m_real zz )				{ x=xx; y=yy; z=zz;}

		void add(const vector3&, const vector3&);
		void sub(const vector3&, const vector3&);
		void cross(const vector3&, const vector3&);

		vector3& operator=(vector3 const& a)
		{
			x=a.x;
			y=a.y;
			z=a.z;
			return *this;
		}
		m_real operator%( vector3 const&) const;
		vector3    operator+( vector3 const& ) const;
		vector3    operator-( vector3 const& ) const;

		void zero(){x=y=z=0;}
		m_real length() const;
	};

	void vector3::add(const vector3& a, const vector3& b)
	{
		x=a.x+b.x;
		y=a.y+b.y;
		z=a.z+b.z;
	}

	void vector3::cross(const vector3& a, const vector3& b)
	{
		x = a.y*b.z - a.z*b.y;
		y = a.z*b.x - a.x*b.z;
		z = a.x*b.y - a.y*b.x;
	}
	void vector3::sub(const vector3& a, const vector3& b)
	{
		x=a.x-b.x;
		y=a.y-b.y;
		z=a.z-b.z;
	}
	m_real vector3::operator%(vector3 const& b) const
	{
		vector3 const& a=*this;
		return a.x*b.x+a.y*b.y+a.z*b.z;
	}

	vector3    vector3::operator+( vector3 const& b) const
	{
		const vector3& a=*this;
		vector3 c;
		c.add(a,b);
		return c;
	}

	vector3    vector3::operator-( vector3 const& b) const
	{
		const vector3& a=*this;
		vector3 c;
		c.sub(a,b);
		return c;
	}

	m_real
	vector3::length() const
	{
		return (m_real)sqrt( x*x + y*y + z*z );
	}
	void register_v(lua_State* L);
	void test_main(lua_State* L)
	{
		register_v(L);

		]]) --writeLaunchLuaDebugger()
		write([[
		luaL_dostring(L, ]]..luacodeInCquote([[
		a=test.vector3()
		a.x=1
		for i=1,1000 do
			a.x=a.x+1
		end
		print('a.x='..a.x)
		]])..[[);
		printf("test_property 1 finished\n");
		]])
		-- following tests works only when isExtendableFromLua ==true
		write(codeDostring([[
		
		a.w=1 -- define additional data
		for i=1,1000 do
			a.w=a.w+1
		end
		print('a.x='..a.x..' a.w='..a.w)
		print(a)
		]]))
		write([[
		printf("test_property2 (extending from lua) finished\n");
		]]) 
		--writePrintStack() 
		write([[
	}
	]])

	buildDefinitionDB(bindTarget)
	writeDefinitions(bindTarget, "register_v")
	flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
end
array.pushBack(gen_lua.number_types, 'm_real')
bindTarget={
	classes={
		-- table name LVectorn will be the class name in lua
		{
			name='vector3', --necessary
			-- the following option (isExtendableFromLua) turned on only when
			-- 1. this class will have additional member data defined from LUA.
			-- 2. this class will be inherited from a LUA class.
			-- otherwise, turn it off (the default) because this has negative impact on the interface speed.
			-- Note, member function (as opposed to member data) can be defined without this variable turned on.
			isExtendableFromLua=true, -- property w will defined in lua.  
			ctors=  -- constructors 
			{
				'()',
				'(m_real xyz)',
				'(m_real x, m_real y, m_real z)',
			},
			properties={  -- easiest way to bind property
				'double x'
			},
			read_properties= -- for finer control
			{
				-- property name, lua function name
				{'y', 'getY'},
				{'z', 'getZ'},
			},
			write_properties=
			{
				{'y', 'setY'},
				{'z', 'setZ'},
			},
			wrapperCode= -- luna_gen doesn't parse this string. just puts it in the cpp output. so you are free to use any valid cpp syntax here.
			[[
			inline static m_real getY(vector3 const& a) { return a.y;}
			inline static m_real getZ(vector3 const& a) { return a.z;}
			inline static void setY(vector3 & a, m_real b) { a.y=b;}
			inline static void setZ(vector3 & a, m_real b) { a.z=b;}
			inline static vector3 __add(vector3 const& a, vector3 const& b)
			{vector3 c;c.add(a,b);return c;}
			inline static vector3 __sub(vector3 const& a, vector3 const& b)
			{vector3 c;c.sub(a,b);return c;}
			inline static m_real dotProduct(vector3 const& a, vector3 const& b)
			{
				return a%b;
			}
			// you can implement custum interface function too. (see custumFunctionsToRegister below)
			static int __tostring(lua_State* L)
			{
				vector3& self=*luna_t::check(L,1);
				std::ostringstream oss;
				oss << "{"<< self.x <<", " << self.y <<", " <<self.z<<"}";
				lua_pushstring(L, oss.str().c_str());

				return 1;
			}
			]],
			staticMemberFunctions= -- const modifiers are ignored
			{
				[[
				vector3 __add(vector3 const& a, vector3 const& b);
				vector3 __sub(vector3 const& a, vector3 const& b);
				m_real dotProduct(vector3 const& a, vector3 const& b);
				m_real getY(vector3 const& a);
				m_real getZ(vector3 const& a);
				void setY(vector3 & a, m_real b);
				void setZ(vector3 & a, m_real b);
				]]
			},
			custumFunctionsToRegister={'__tostring'},
			memberFunctions = -- list of strings of c++ function declarations.
			{
				-- you can enter multiline texts that looks like a cleaned header file
				[[
				void add(const vector3&, const vector3&);
				void sub(const vector3&, const vector3&);
				void zero();
				void cross(const vector3&, const vector3&);
				vector3 length() const;
				vector3    operator+( vector3 const& ) const;
				vector3    operator-( vector3 const& ) const;
				void operator=(const vector3&); @ assign // note that the signature can be different. 
				]],
				-- @ means 'rename'
			},
		},
	}
}
namespaces={
	-- these are cpp class name, not lua class name, because lua name may not be unique. 
	test={'vector3'}
}
