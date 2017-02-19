-- this is the simplest example.
luaCode=[[
	a=vector3()
	a.x=1
	for i=1,1000 do
		a.x=a.x+1
	end
	print('a.x='..a.x)

	function getSum(c)
		local a=vector3()
		a.x=0
		a.y=2
		a.z=3
		local b=vector3(3,4,5)
		for i=1,1000 do
			a.x=a.x+1
		end
		return (a+b+c).x
	end
]]

cppCode=[[
#include <math.h>
#include "test.hpp"
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
		std::string tostring() const;
	};
	std::string vector3::tostring() const
	{
		char temp[1000];
		snprintf(temp, 999,"vector3(%f, %f %f)", x,y,z);
		return std::string(temp);
	}

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
	void register_vector3(lua_State* L);
	void test_main(lua_State* L)
	{
		register_vector3(L);
		luaL_dostring(L, ]]..luacodeInCquote(luaCode)..[[);
		lunaStack l(L);
		l.getglobal("getSum");
		vector3 c(10,20,30);
		l.push<vector3>(c);
		l.call(1,1);
		double out;
		l>>out;
		TEST_CHECK(out>1013-0.0001 && out <1013+0.0001);
	}
]]
function generate()
	writeIncludeBlock()
	write(cppCode)
	buildDefinitionDB(bindTarget)
	writeDefinitions(bindTarget, "register_vector3")
	flushWritten(input_filepath..'/generated/'..string.sub(input_filename,1,-4)..'cpp')
end
array.pushBack(gen_lua.number_types, 'm_real')
bindTarget={
	classes={
		-- table name LVectorn will be the class name in lua
		{
			name='vector3', --necessary
			ctors=  -- constructors 
			{
				'()',
				'(m_real xyz)',
				'(m_real x, m_real y, m_real z)',
			},
			properties={ 'double x', 'double y', 'double z'},
			memberFunctions = -- list of strings of c++ function declarations.
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
	}
}
