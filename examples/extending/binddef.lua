array.pushBack(gen_lua.number_types, 'm_real')
bindTarget={
	classes={
		{
			name='mathlib.vector3', -- lua name is alway necessary
			className='vector3', -- consider vector3 as c++ class name as opposed to the default test::vector3.
			ctors=  -- constructors 
			{
				'()',
				'(m_real xyz)',
				'(m_real x, m_real y, m_real z)',
			},
			properties={  -- easiest way to bind property
				'double x', 'double y', 'double z'
			},
			wrapperCode= -- luna_gen doesn't parse this string. just puts it in the cpp output. so you are free to use any valid cpp syntax here.
			[[
			// you can implement custom interface function too. (see customFunctionsToRegister below)
			static int __tostring(lua_State* L)
			{
				vector3& self=*luna_t::check(L,1);
				std::ostringstream oss;
				oss << "{"<< self.x <<", " << self.y <<", " <<self.z<<"}";
				lua_pushstring(L, oss.str().c_str());

				return 1;
			}
			]],
			customFunctionsToRegister={'__tostring'},
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
				void operator=(const vector3&); @ assign // note that the signature can be different. 
				bool operator==(vector3 const& b) const
				bool operator<=(vector3 const& b) const
				bool operator<(vector3 const& b) const
				]],
				-- @ means 'rename'
			},
			staticMemberFunctions={
				[[
				vector3    operator-(vector3 const& a, vector3 const& b) ;
				]]
			}
		},
	}
}

function generate()
	writeIncludeBlock() 
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
		// can bind both member and non-member operators
		vector3    operator+( vector3 const& ) const;
		friend vector3  operator-(vector3 const& a, vector3 const& b) ;
		bool operator==(vector3 const& b) const { return x==b.x && y==b.y && z==b.z;}
		bool operator<=(vector3 const& b) const { return length()<=b.length() ;}
		bool operator<(vector3 const& b) const { return length()<b.length() ;}

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

	vector3    operator-(vector3 const& a, vector3 const& b) 
	{
		vector3 c;
		c.sub(a,b);
		return c;
	}

	m_real
	vector3::length() const
	{
		return (m_real)sqrt( x*x + y*y + z*z );
	}
	]])

	buildDefinitionDB(bindTarget)
	writeDefinitions(bindTarget, "register_mathlib")
	flushWritten(source_path..'/binddef.cpp')
end
