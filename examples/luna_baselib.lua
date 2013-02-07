--gen_lua.use_profiler=true -- uses performance profiler. See test_profiler sample.
array.pushBack(gen_lua.number_types, 'm_real') -- m_real is a type-def of double.
array.pushBack(gen_lua.enum_types, 'boolN::zeroCrossingMode')
array.pushBack(gen_lua.enum_types, 'uchar')
-- snippets for luabind users:
-- luabind -> lunagen

--[[ luabind:
luabind::def("createVRMLskin", &RE::createVRMLskin,luabind::adopt(luabind::result))
-> luna-gen:
PLDPrimVRML* RE::createVRMLskin(VRMLloader*pTgtSkel, bool bDrawSkeleton) @ ;adopt=true; 


luabind:
		.enum_("constants")
		[
			luabind::value("EULER",OpenHRP::DynamicsSimulator::EULER),
			luabind::value("RUNGE_KUTTA",OpenHRP::DynamicsSimulator::RUNGE_KUTTA)
		]
-> luna-gen:

		.scope_[..] -> staticMemberFunctions={...}

		#ifndef AAA
			luabind::def("abc"...)
		#endif
		->
		void abc() @ ;ifndef=AAA;
]]--
bindTarget={
	classes={
		{
			name='util.PerfTimer2',
			className='QPerformanceTimerCount2',
			ctors={'()'},
			memberFunctions={[[
			void reset()
			void start()
			void pause()
			long stop()
			]]}
		},
		{
			name='util.FractionTimer',
			className='FractionTimer',
			ctors={'()'},
			staticMemberFunctions={[[
			static void FractionTimer::init()
			static double FractionTimer::stopOutside()
			static double FractionTimer::stopInside()
			]]}
		},
		{
			name='boolN',
			ctors={'()','(int n)'},
			wrapperCode=[[
			  static boolNView _range(boolN const& a, int start, int end)
			  {
				  return boolNView (a._vec, a._start+start, a._start+end);
			  }
			  ]],
			enums={
				{"ZC_MIN", "(int)boolN::ZC_MIN"},
				{"ZC_MAX", "(int)boolN::ZC_MAX"},
				{"ZC_ALL", "(int)boolN::ZC_ALL"},
			},
			staticMemberFunctions={[[
										   static boolNView _range(boolN const& a, int start, int end) @ range
			  ]]},
			  enums={
				  {"ZC_MIN", "(int)boolN::ZC_MIN"},
				  {"ZC_MAX", "(int)boolN::ZC_MAX"},
				  {"ZC_ALL", "(int)boolN::ZC_ALL"},
			  },
			memberFunctions={[[
									 void assign(const boolN& other)
									 void assign(const boolN& other)
									 void set(int i, bool b)
									 void setAllValue(bool b)
									 virtual void resize(int n)
									 int size();
									 TString output() @ __tostring
									 bool operator[](int i) @ __call
									 void findZeroCrossing(const vectorn& signal, boolN::zeroCrossingMode mode);
									 void findLocalOptimum(const vectorn& signal, boolN::zeroCrossingMode mode);
						 ]]}
		},
		{
			name='boolNView',
			inheritsFrom='boolN'
		},
		{
			name='CPixelRGB8',
			ctors={'(uchar, uchar, uchar)'},
			properties={'uchar R', 'uchar G', 'uchar B'},
		},
		{
			name='intvectorn',
			ctors=  -- constructors 
			{
				'()',
				'(int size)',
			},
			wrapperCode=
			[[
			inline static int get(intvectorn const& a, int i)
			{
				return a[i];
			}
			inline static void set(intvectorn & a, int i, int d)
			{
				a[i]=d;
			}
			inline static void radd(intvectorn & a, int b)	{a+=b;}
			inline static void rsub(intvectorn & a, int b)	{a-=b;}
			inline static void rdiv(intvectorn & a, int b) {a/=b;}
			inline static void rmult(intvectorn & a, int b) {a*=b;}
			inline static void rmult(intvectorn & a, intvectorn const&b) {for(int i=0; i<a.size(); i++) a[i]*=b[i];}
			inline static void radd(intvectorn & a, intvectorn const& b)	{a+=b;}
			inline static void rsub(intvectorn & a, intvectorn const& b)	{a-=b;}
			static int setValues(lua_State* L)
			{
				intvectorn& self=*luna_t::check(L,1);
				int n=lua_gettop(L)-1;
				self.setSize(n);
				for (int i=0;i<n; i++)
					self(i)=lua_tonumber(L,i+2);
				return 0;
			}
			]],
			staticMemberFunctions=
			{
				{'int get(intvectorn const& a, int i);'},
				{'int get(intvectorn const& a, int i);', rename='__call'},
				{'void set(intvectorn & a, int i, m_real d);'},
				[[void radd(intvectorn & a, int b);
				void rsub(intvectorn & a, int b);
				void rdiv(intvectorn & a, int b);
				void rmult(intvectorn & a, int b);
				void rmult(intvectorn & a, intvectorn const&b);
				void radd(intvectorn & a, intvectorn const& b);
				void rsub(intvectorn & a, intvectorn const& b);
				]]
			},
			memberFunctions=
			{
				[[
				TString output() @ __tostring
					int maximum() const;
					int minimum() const;
					int sum() const;
				void pushBack(int x)
				int size()
				void setSize(int)
				void resize(int)
				void setValue(int i, int d) @ set	
				intvectornView range(int start, int end, int step)
				intvectornView range(int start, int end)
				void  colon(int start, int end, int stepSize);
				void setAllValue(int v);
				]]
			},
			customFunctionsToRegister ={'setValues'},
		},
		{
			name='TRect',
			ctors={"()","(int,int,int,int)"},
			properties={"int left", "int right", "int top", "int bottom"},
		},
		{
			name='CImage',
			ctors={"()"},
			memberFunctions={[[
			int GetWidth() const ;
			int GetHeight() const ;
			bool Load(const char* filename);
			bool Save(const char* filename);
			bool save(const char* filename, int BPP);
			bool Create(int width, int height); @ create
			void CopyFrom(CImage const& other);
			]]},
			staticMemberFunctions={[[
			void Imp::drawBox(CImage& inout, TRect const& t, int R, int G, int B);
			void Imp::sharpen(CImage& inout, double factor, int iterations);
			void Imp::contrast(CImage& inout, double factor);
			void Imp::gammaCorrect(CImage& inout, double factor);
			void Imp::dither(CImage& inout, int levels);
			void Imp::resize(CImage& inout, int width, int height);
			void Imp::blit(CImage& out, CImage const& in, TRect const& rect_in, int x, int y);
			void Imp::concatVertical(CImage& out, CImage const& a, CImage const& b);
			void Imp::crop(CImage& out, CImage const& in, int left, int top, int right, int bottom);
			void Imp::rotateRight(CImage& other);
			void Imp::rotateLeft(CImage& other);
			]]}
		},
		{ 
			name='TStrings',
			ctors={'()'},
			wrapperCode=[[
			inline static void set(TStrings& a, int i, const char* b)
			{
				a[i]=b;
			}
			inline static void set(TStrings& a, int i)
			{
				a[i]="";
			}
			]],
			staticMemberFunctions={[[
			void set(TStrings& a, int i, const char* b)
			void set(TStrings& a, int i)
			]]},
			memberFunctions={[[
			TString operator[](int i)	@ __call
			TString data(int i)					
			TString back()						
			void init(int n);
			int size() const						
			void resize(int n)					
			void pushBack(const TString& other)
			TString prefix() const;	// 모든 문자열이 같은 prefix로 시작하는 경우 해당 prefix return.
			void trimSamePrefix(const TStrings& other);	// 모든 문자열이 같은 prefix로 시작하는 경우 잘라준다.
			int find(const char* other) const;
			]]}
		},
{
	name='intvectornView',
	inheritsFrom='intvectorn'
},
		{
			name='intmatrixn'
		},
		{
			name='util.BinaryFile',
			className='BinaryFile',
			ctors={[[
						   ()
						   (bool bReadToMemory)
						   (bool bWrite, const char* filename)
			   ]]},
			memberFunctions={
[[
	bool openWrite(const char *fileName);
	bool openRead(const char *fileName);
	void close();
	void packInt(int num);
	void packFloat(double num);
	void pack(const char *str);
	void pack(const vectorn& vec);
	void pack(const vector3& vec);
	void pack(const quater& vec);
	void pack(const intvectorn& vec);
	void pack(const matrixn& mat);
	void pack(const intmatrixn& mat);
	void pack(const vector3N& mat);
	void pack(const quaterN& mat);
	void pack(const TStrings& aSz);
	void pack(const boolN& vec);
	void pack(const matrix4& mat);
	int	unpackInt()	
	double unpackFloat()	
	TString unpackStr();
	void unpack(vectorn& vec);
	void unpack(vector3& vec);
	void unpack(quater& vec);
	void unpack(intvectorn& vec);
	void unpack(matrixn& mat);
	void unpack(intmatrixn& mat);
	void unpack(TStrings& aSz);
	void unpack(boolN& vec);
	void unpack(quaterN& mat);
	void unpack(vector3N& mat);
	void unpack(matrix4& mat);
	int _unpackInt()	
	double _unpackFloat()
	TString _unpackStr();
	void _unpackVec(vectorn& vec);
	void _unpackMat(matrixn& mat);
]]},
				enums={
					{"TYPE_INT", "(int)BinaryFile::TYPE_INT"},
					{"TYPE_FLOAT", "(int)BinaryFile::TYPE_FLOAT"},
					{"TYPE_FLOATN", "(int)BinaryFile::TYPE_FLOATN"},
					{"TYPE_INTN", "(int)BinaryFile::TYPE_INTN"},
					{"TYPE_BITN", "(int)BinaryFile::TYPE_BITN"},
					{"TYPE_FLOATMN", "(int)BinaryFile::TYPE_FLOATMN"},
					{"TYPE_INTMN", "(int)BinaryFile::TYPE_INTMN"},
					{"TYPE_BITMN", "(int)BinaryFile::TYPE_BITMN"},
					{"TYPE_STRING", "(int)BinaryFile::TYPE_STRING"},
					{"TYPE_STRINGN", "(int)BinaryFile::TYPE_STRINGN"},
					{"TYPE_ARRAY", "(int)BinaryFile::TYPE_ARRAY "},
					{"TYPE_EOF", "(int)BinaryFile::TYPE_EOF"},
				}
			
		},
		{
			name='transf',
			wrapperCode=[[
			inline 	static void assign(transf &b, transf const& a)
			{
				b.rotation=a.rotation;
				b.translation=a.translation;
			}
			]],
			ctors={
				[[
				()
				(quater const&, vector3 const&)
				(matrix4 const&)
				]]
			},
			properties={ 'quater rotation', 'vector3 translation'},
			memberFunctions={
				[[
				transf inverse() const;
				transf toLocal(transf const& global) const;
				transf toGlobal(transf const& local) const;

				quater toLocalRot(quater const& ori) const;
				quater toGlobalRot(quater const& ori) const;
				quater toLocalDRot(quater const& ori) const;
				quater toGlobalDRot(quater const& ori) const;

				vector3 toLocalPos(vector3 const& pos) const;
				vector3 toGlobalPos(vector3 const& pos) const;
				vector3 toLocalDir(vector3 const& dir) const;
				vector3 toGlobalDir(vector3 const& dir) const;
				void difference(transf const& f1, transf const& f2);			//!< f2*f1.inv
				void identity();
				void operator=(matrix4 const& a);
				vector3 encode2D() const;
				void decode2D(vector3 const& in);
	void leftMult(const transf& a);	//!< this=a*this;
	void operator*=(const transf& a);	//!< this=this*a;
				]]
			},
			staticMemberFunctions={
				[[
				static void assign(transf &b, transf const& a)
    transf       operator* ( transf const&, transf const& );
    vector3       operator* ( transf const& , vector3 const&);
				]]
			},
		},
		{
			name='vector3N',
			ctors=
			{
				'()',
				'(int)',
			},
			memberFunctions=
			{
				[[
						vector3& row(int)
						int rows() const
						int size() const
						void setSize(int)
						void resize(int)
						void reserve(int)
						vector3NView range(int,int)
						vector3NView range(int,int,int)
						void assign(vector3N const&)
						vector3& value(int) @ at
						vector3& value(int) @ __call
						void transition(vector3 const&, vector3 const&, int duration) 
						void setAllValue(vector3)
						vectornView x()
						vectornView y()
						vectornView z()
				]]
				-- ,add,sub,mul
			},
			wrapperCode=[[
					static TString __tostring(vector3N const& a)
						{
							return matView(a).output();
						}
      static vector3 sampleRow(vector3N const& in, m_real criticalTime)
      {
	vector3 out;
	//!< 0 <=criticalTime<= numFrames()-1
	// float 0 이 정확하게 integer 0에 mapping된다.
	int a;
	float t;
	
	a=(int)floor(criticalTime);
	t=criticalTime-(float)a;
	
	if(t<0.005)
	  out=in.row(a);
	else if(t>0.995)
	  out=in.row(a+1);
	else
	  {
	    if(a<0)
	      out.interpolate(t-1.0, in.row(a+1), in.row(a+2));
	    else if(a+1>=in.rows())
	      out.interpolate(t+1.0, in.row(a-1), in.row(a));
	    else
	      out.interpolate(t, in.row(a), in.row(a+1));
	  }
	return out;
      }
				]],
			staticMemberFunctions=
			{
				[[
      vector3 sampleRow(vector3N const& in, m_real criticalTime)
						matrixnView matView(vector3N const& a, int start, int end)
						matrixnView matView(vector3N const& a)
						TString __tostring(vector3N const& a)
				]]
			},
		},
		{
			name='vector3NView', inheritsFrom='vector3N',
		},
		{
			name='quaterN',
			ctors=
			{
				'()',
				'(int)',
			},
			memberFunctions=
			{
				[[
						quater& row(int)
						int rows() const
						int size() const
						void setSize(int)
						void resize(int)
						void reserve(int)
						quaterNView range(int,int)
						quaterNView range(int,int,int)
						void assign(quaterN const&)
						quater& value(int) @ at
						quater& value(int) @ __call
						void transition(quater const&, quater const&, int duration) 
						void setAllValue(quater)
				]]
				-- sampleRow
			},
			wrapperCode=[[
					static TString __tostring(quaterN const& a)
						{
							return matView(a).output();
						}
      static quater sampleRow(quaterN const& in, m_real criticalTime)
      {
	quater out;
	//!< 0 <=criticalTime<= numFrames()-1
	// float 0 이 정확하게 integer 0에 mapping된다.
	int a;
	float t;
	
	a=(int)floor(criticalTime);
	t=criticalTime-(float)a;
	
	if(t<0.005)
	  out=in.row(a);
	else if(t>0.995)
	  out=in.row(a+1);
	else
	  {
	    if(a<0)
	      out.safeSlerp(in.row(a+1), in.row(a+2), t-1.0);
	    else if(a+1>=in.rows())
	      out.safeSlerp(in.row(a-1), in.row(a), t+1.0);
	    else
	      out.safeSlerp( in.row(a), in.row(a+1),t);
	  }
	return out;
      }
				]],
			staticMemberFunctions=
			{
				[[
				static quater sampleRow(quaterN const& in, m_real criticalTime)
						matrixnView matView(quaterN const& a, int start, int end)
						matrixnView matView(quaterN const& a)
					static TString __tostring(quaterN const& a)
				]]
			},
		},
		{
			name='intIntervals',
			decl=[[#include "../../BaseLib/math/intervals.h"]],
			ctors={'()'},
			memberFunctions={
				[[
					int numInterval() const
					int size() const	
					void setSize(int n)	
					void resize(int n)
					void removeInterval(int i);
					int start(int iInterval) const	 @ startI
					int end(int iInterval) const @ endI
					void load(const char* filename);
					void pushBack(int start, int end)
					int findOverlap(int start, int end, int startInterval);
					int findOverlap(int start, int end);
					void runLengthEncode(const boolN& source)
					void runLengthEncode(const boolN& source , int start, int end);
					void runLengthEncode(const intvectorn& source);
					void findConsecutiveIntervals(const intvectorn& source);
					void runLengthEncodeCut(const boolN& cutState);
					void encodeIntoVector(intvectorn& out);
					void decodeFromVector(const intvectorn& in);
					void offset(int offset);
					void toBitvector(boolN& bitVector);
					void runLengthEncode( const boolN& source)
				]],
			},
		},
		{
			name='quaterNView', inheritsFrom='quaterN',
		},
		{
			name='vectorn', --necessary
			ctors=  -- constructors 
			{
				'()',
				'(int size)',
			},
			wrapperCode=
			[[
			inline static m_real get(vectorn const& a, int i)
			{
				return a[i];
			}
			inline static void set(vectorn & a, int i, m_real d)
			{
				a[i]=d;
			}
			inline static void radd(vectorn & a, m_real b)	{a+=b;}
			inline static void rsub(vectorn & a, m_real b)	{a-=b;}
			inline static void rdiv(vectorn & a, m_real b) {a/=b;}
			inline static void rmult(vectorn & a, m_real b) {a*=b;}
			inline static void rmult(vectorn & a, vectorn const&b) {for(int i=0; i<a.size(); i++) a[i]*=b[i];}
			inline static void setAllValue(vectorn & a, m_real b) {a.setAllValue(b);}
			inline static void radd(vectorn & a, vectorn const& b)	{a+=b;}
			inline static void rsub(vectorn & a, vectorn const& b)	{a-=b;}
			inline static void smoothTransition(vectorn &c, m_real s, m_real e, int size)
			{
				c.setSize(size);
				for(int i=0; i<size; i++)
					{
						m_real sv=sop::map(i, 0, size-1, 0,1);
						c[i]=sop::map(sop::smoothTransition(sv), 0,1, s, e);
					}
				}
			static int setValues(lua_State* L)
			{
				vectorn& self=*luna_t::check(L,1);
				int n=lua_gettop(L)-1;
				self.setSize(n);
				for (int i=0;i<n; i++)
					self(i)=lua_tonumber(L,i+2);
				return 0;
			}
			inline static vectorn mult(m_real b, vectorn const& a)
				{
					return a*b;
				}
				inline static void clamp(vectorn &cc, double a, double b){
					for (int i=0; i<cc.size(); i++)
					{
						double c=cc[i];
						c=(c<a)?a:c;
						c=(c>b)?b:c;
						cc[i]=c;
					}
				}
				inline static void clamp(vectorn &cc, vectorn const& aa, vectorn const&bb){
					assert(aa.size()==bb.size());
					assert(aa.size()==cc.size());
					for (int i=0; i<cc.size(); i++)
					{
						double c=cc[i];
						double a=aa[i];
						double b=bb[i];
						c=(c<a)?a:c;
						c=(c>b)?b:c;
						cc[i]=c;
					}
				}
			]],
			staticMemberFunctions=
			{
				{'m_real get(vectorn const& a, int i);'},
				{'m_real get(vectorn const& a, int i);', rename='__call'},
				{'void set(vectorn & a, int i, m_real d);'},
				[[void radd(vectorn & a, m_real b);
				void rsub(vectorn & a, m_real b);
				void rdiv(vectorn & a, m_real b);
				void rmult(vectorn & a, m_real b);
				void rmult(vectorn & a, vectorn const&b);
				void clamp(vectorn &cc, double a, double b);
				void clamp(vectorn &cc, vectorn const& a, vectorn const& b);
				void setAllValue(vectorn & a, m_real b) ;
				void radd(vectorn & a, vectorn const& b);
				void rsub(vectorn & a, vectorn const& b);
				matrixnView matView(vectorn const& a, int start, int end)
				matrixnView matView(vectorn const& a, int col)
				vector3NView vec3View(vectorn const&)
				quaterNView quatView(vectorn const&)
				static void smoothTransition(vectorn &c, m_real s, m_real e, int size)
	  m_real v::sample(vectorn const& in, m_real criticalTime)
	  void v::interpolate(vectorn & out, m_real t, vectorn const& a, vectorn const& b) @ interpolate
	vectorn operator+( vectorn const& a, vectorn const& b);
	vectorn operator-( vectorn const& a, vectorn const& b);
	vectorn operator*( vectorn const& a, vectorn const& b );
	vectorn operator+( vectorn const& a, m_real b);
	vectorn operator-( vectorn const& a, m_real b);
	vectorn operator*( vectorn const& a, m_real b);
	vectorn operator/( vectorn const& a, m_real b);
	vectorn operator*( matrixn const& a, vectorn const& b );
			vectorn mult(m_real b, vectorn const& a) @ __mul
				]]
			},
			memberFunctions=
			{
				[[
				void sub(vectorn const& a, vectorn const& b);
				void add(vectorn const& a, vectorn const& b);
				void assign(const vector3& other);
				void assign(const quater& other);
				void assign(const vectorn &other);
				m_real minimum();
				m_real maximum();
				TString output() @ __tostring
				vector3 toVector3()	const	
				vector3 toVector3(int startIndex)	const	
				quater toQuater() const	
				quater toQuater(int startIndex) const	
				void setVec3( int start, const vector3& src)
				void setQuater( int start, const quater& src)
				inline void pushBack(double x)
				int size()
				void setSize(int)
				void resize(int)
				void setValue(int i, double d) @ set	
				vectornView range(int start, int end, int step)
				vectornView range(int start, int end)
				m_real length() const ;
				m_real minimum() const;
				m_real maximum()	const;
				m_real sum()	const;
				m_real squareSum() const;
				m_real avg() const;
				void minimum(const matrixn& other) 
				void maximum(const matrixn& other) 
				void lengths(matrixn const& in)    
				int argMin() const
				int argMax() const
				int argNearest(double) const;
				void colon(m_real start, m_real stepSize,int nSize);
				void colon(m_real start, m_real stepSize);
				void linspace(m_real x1, m_real x2, int nSize);
				void linspace(m_real x1, m_real x2);
				void uniform(m_real x1, m_real x2, int nSize);
				void uniform(m_real x1, m_real x2);
				matrixnView column() const;	// return n by 1 matrix, which can be used as L-value (reference matrix)
				matrixnView row() const;	// return 1 by n matrix, which can be used as L-value (reference matrix)
				
				void minimum(const matrixn& other)
				void maximum(const matrixn& other)
				void lengths(matrixn const& in)   
				]]
			},
			customFunctionsToRegister ={'setValues'},

		},
		{
			name='vectornView', inheritsFrom='vectorn',
		},
		{
			name='matrix3',
			wrapperCode=[[
			static TString out(matrix3& l)
			{
				TString v;
				v.format(" %f %f %f\n %f %f %f\n %f %f %f\n", l._11,l._12,l._13,l._21,l._22,l._23,l._31,l._32,l._33);
				return v;
			}
			]],
			ctors=
			{
				[[
				()
				(matrix3 const&)
				]]
			},	
			properties={'double _11','double _12','double _13',
			'double _21','double _22','double _23',
			'double _31','double _32','double _33',
					},
			staticMemberFunctions=
			{
				[[
				vector3 operator*(matrix3 const& a, vector3 const& b)
				vector3 operator*(vector3 const& b, matrix3 const& a)
				matrix3 operator*(matrix3 const& a, matrix3 const& b)
				TString out(matrix3 &l) @ __tostring
				]]
			},
			memberFunctions=
			{
				[[
					void setValue( m_real a00, m_real a01, m_real a02, m_real a10, m_real a11, m_real a12, m_real a20, m_real a21, m_real a22 );
					void zero();
					void identity();
					void transpose( void );
					void negate( void );
					bool inverse(matrix3 const& a);
					void setTilde( vector3 const &v );
					void setFromQuaternion(quater const& q);
					void mult(matrix3 const& a,matrix3 const& b);
					void mult(matrix3 const& a, m_real b);
					]]
			},
		},
		{
			name='matrix4', --necessary
			ctors=  -- constructors 
			{
				[[
				()
				(const quater&, const vector3&)
				(const transf&)
				]]
			},
			properties={'double _11','double _12','double _13','double _14',
			'double _21','double _22','double _23','double _24',
			'double _31','double _32','double _33','double _34',
			'double _41','double _42','double _43','double _44',},
			wrapperCode=[[
			inline static void assign(matrix4& l, matrix4 const& m)
			{
				l=m;
			}
			static TString out(matrix4& l)
			{
				TString v;
				v.format(" %f %f %f %f\n %f %f %f %f\n %f %f %f %f\n %f %f %f %f\n", l._11,l._12,l._13,l._14,l._21,l._22,l._23,l._24,l._31,l._32,l._33,l._34,l._41,l._42,l._43,l._44);
				return v;
			}
			static matrix4 inverse(matrix4 const& m)
			{
				matrix4 t;
				t.inverse(m);
				return t;
			}
			]],
			staticMemberFunctions={
				[[
				inline static void assign(matrix4& l, matrix4 const& m)
				static TString out(matrix4& l) @__tostring
static matrix4 inverse(matrix4 const& m)
				]]
			},
			memberFunctions={
				[[
				void identity()	
				void setRotation(const quater& q);
				void setRotation(const matrix3& m);
				void setRotation(const vector3& axis, m_real angle);
				void setScaling(m_real sx, m_real sy, m_real sz);
				void leftMultRotation(const quater& b);
				void leftMultRotation(const vector3& axis, m_real angle);
				void leftMultTranslation(const vector3& vec);
				void leftMultScaling(m_real sx, m_real sy, m_real sz);
				void inverse(const matrix4& a);
				matrix4 operator*(matrix4 const& a) const
				vector3 operator*(vector3 const& a) const;
				matrix4 operator+(matrix4 const& a) const 
				matrix4 operator-(matrix4 const& a) const
				matrix4 operator=(matrix4 const& b) const
				void operator*=(double b) 
				]]
			},
		},
		{
			name='matrixn', --necessary
			ctors=  -- constructors 
			{
				'()',
				'(int rows, int cols)',
			},
			customFunctionsToRegister ={'setValues'},
			wrapperCode=
			[[
			static int setValues(lua_State* L)
			{
				matrixn& self=*luna_t::check(L,1);
				int n=lua_gettop(L)-1;
				if (n!=self.cols()*self.rows()) luaL_error(L, "setValues(nrows, ncols, values...)");
				int c=2;
				for (int i=0;i<self.rows(); i++)
					for (int j=0;j<self.cols(); j++)
						self(i,j)=lua_tonumber(L,c++);
				return 0;
			}
			inline static matrixn __mul(matrixn const& a, m_real b)
			{matrixn c;c.mult(a,b);return c;}
			inline static matrixn __mul(m_real b, matrixn const& a)
			{matrixn c;c.mult(a,b);return c;}
			inline static matrixn __mul(matrixn const& a, matrixn const& b)
			{matrixn c;c.mult(a,b);return c;}

			inline static matrixn __add(matrixn const& a, m_real b)
			{matrixn c;c.add(a,b);return c;}
			inline static matrixn __add(m_real b, matrixn const& a)
			{matrixn c;c.add(a,b);return c;}

			inline static matrixn __div(matrixn const& a, m_real b)
			{
				matrixn c;
				c.mult(a,1.0/b);
				return c;
			}

			//static void radd(matrixn & a, m_real b)	{a+=b;}
			//static void rsub(matrixn & a, m_real b)	{a-=b;}
			inline static void rdiv(matrixn & a, m_real b) {a/=b;}
			inline static void rmult(matrixn & a, m_real b) {a*=b;}
			inline static void setAllValue(matrixn & a, m_real b) {a.setAllValue(b);}
			inline static void radd(matrixn & a, matrixn const& b)	{a+=b;}
			inline static void rsub(matrixn & a, matrixn const& b)	{a-=b;}

			inline static void pushBack(matrixn& mat, const vectorn& v) { mat.pushBack(v);}

			inline static void transpose(matrixn& a)
			{
				matrixn c;
				c.transpose(a);
				a=c;
			}
			inline static void sampleRow(matrixn const& in, m_real criticalTime, vectorn& out){
				out.setSize(in.cols());
				//!< 0 <=criticalTime<= numFrames()-1
				// float 0 이 정확하게 integer 0에 mapping된다.
				int a;
				float t;

				a=(int)floor(criticalTime);
				t=criticalTime-(float)a;

				if(t<0.005)
					out=in.row(a);
				else if(t>0.995)
					out=in.row(a+1);
				else {
					if(a<0)
						v::interpolate(out, t-1.0, in.row(a+1), in.row(a+2));
					else if(a+1>=in.rows())
						v::interpolate(out, t+1.0, in.row(a-1), in.row(a));
					else
						v::interpolate(out, t, in.row(a), in.row(a+1));
					}
				}


				]]
				,staticMemberFunctions=
				{
					[[
							matrixn operator-( matrixn const& a, matrixn const& b);
							matrixn operator+( matrixn const& a, matrixn const& b);
					static matrixn __mul(matrixn const& a, m_real b)
					static matrixn __mul(m_real b, matrixn const& a)
					static matrixn __mul(matrixn const& a, matrixn const& b)
					static matrixn __add(matrixn const& a, m_real b)
					static matrixn __add(m_real b, matrixn const& a)
					static matrixn __div(matrixn const& a, m_real b)
					static void rdiv(matrixn & a, m_real b) 
					static void rmult(matrixn & a, m_real b) 
					static void setAllValue(matrixn & a, m_real b) 
					static void radd(matrixn & a, matrixn const& b)	
					static void rsub(matrixn & a, matrixn const& b)	
					static void pushBack(matrixn& mat, const vectorn& v) 
					static void transpose(matrixn& a)
					static void sampleRow(matrixn const& in, m_real criticalTime, vectorn& out)
					vector3NView vec3ViewCol(matrixn const& a, int startCol)
					quaterNView quatViewCol(matrixn const& a, int startCol)
					void m::LUinvert(matrixn& out, const matrixn& in); @ inverse
					void m::pseudoInverse(matrixn& out, const matrixn& in); @ pseudoInverse
					]]
				},
				memberFunctions=
				{
					[[
							double getValue(int,int) @ __call
							double getValue(int,int) @ get
							void setValue(int,int,double) @ set
							int rows()
							int cols()
							vectornView		row(int i)const	
							vectornView		column(int i)const
							vectornView		diag() const		
							void transpose(matrixn const& o)
							void assign(matrixn const& o)
							void setSize(int, int)
							void resize(int, int)
							TString output() @ __tostring
							void setAllValue(double)
							matrixnView range(int, int, int, int)
							double minimum()
							double maximum()
							double sum()
							void pushBack(vectorn const& o)
							void mult( matrixn const&, matrixn const& );
							void multABt(matrixn const& a, matrixn const& b); //!< a*b^T
							void multAtB(matrixn const& a, matrixn const& b); //!< a^T*b
							void multAtBt(matrixn const& a, matrixn const& b); //!< a^T*b^T
							void mult( matrixn const& a, double b );
					]]
				},
			},
		{
			name='matrixnView', inheritsFrom='matrixn',
			ctors={
				[[
						(const matrixn& )
						(const matrixnView&)
				]]
			},
		},
			{
				name='vector3', --necessary
				ctors=  -- constructors 
				{
					'()',
					'(double xyz)',
					'(double x, double y, double z)',
				},
				read_properties=
				{
					-- property name, lua function name
					{'x', 'getX'},
					{'y', 'getY'},
					{'z', 'getZ'},
				},
				write_properties=
				{
					{'x', 'setX'},
					{'y', 'setY'},
					{'z', 'setZ'},
				},
				wrapperCode=
				[[
				inline static double getX(vector3 const& a) { return a.x;}
				inline static double getY(vector3 const& a) { return a.y;}
				inline static double getZ(vector3 const& a) { return a.z;}
				inline static void setX(vector3 & a, m_real b) { a.x=b;}
				inline static void setY(vector3 & a, m_real b) { a.y=b;}
				inline static void setZ(vector3 & a, m_real b) { a.z=b;}
				inline static void set(vector3 & a, m_real x, m_real y, m_real z) {a.x=x; a.y=y; a.z=z;}
				inline static vector3 __mul(vector3 const& a, m_real b)
				{vector3 c;c.mult(a,b);return c;}
				inline static vector3 __mul(m_real b, vector3 const& a)
				{vector3 c;c.mult(a,b);return c;}
				inline static vector3 __div(vector3 const& a, m_real b)
				{
					vector3 c;
					c.mult(a,1.0/b);
					return c;
				}
				inline static vector3 __add(vector3 const& a, vector3 const& b)
				{vector3 c;c.add(a,b);return c;}
				inline static vector3 __sub(vector3 const& a, vector3 const& b)
				{vector3 c;c.sub(a,b);return c;}
				inline static double dotProduct(vector3 const& a, vector3 const& b)
				{
					return a%b;
				}
				// you can implement custom interface function too. (see customFunctionsToRegister below)
					static int __tostring(lua_State* L)
					{
						vector3& self=*luna_t::check(L,1);
						lua_pushstring(L, self.output().ptr());
						return 1;
					}
					static vector3 __unm(vector3 const& a,vector3 const& a2)
					{ return a*-1;}
					]],
					staticMemberFunctions=
					{
						[[
						vector3 __mul(vector3 const& a, double b);
						vector3 __mul(double b, vector3 const& a);
						vector3 __div(vector3 const& a, double b);
						vector3 __add(vector3 const& a, vector3 const& b);
						vector3 __sub(vector3 const& a, vector3 const& b);
						double dotProduct(vector3 const& a, vector3 const& b);
						double getX(vector3 const& a);
						double getY(vector3 const& a);
						double getZ(vector3 const& a);
						void setX(vector3 & a, m_real b);
						void setY(vector3 & a, m_real b);
						void setZ(vector3 & a, m_real b);
						void set(vector3 & a, m_real ,m_real, m_real);
						void set(vector3 & a, m_real ,m_real, m_real); @ setValue
							vector3 __unm(vector3 const& a,vector3 const & a2)
						]]
					},
					customFunctionsToRegister={'__tostring'},
					memberFunctions = -- list of strings of c++ function declarations.
					{
						-- you can enter multiline texts that looks like a cleaned header file
						[[
						void add(const vector3&, const vector3&);
						void sub(const vector3&, const vector3&);
						void zero();
						void operator*=(double);
						void operator*=(double); @ scale
						void cross(const vector3&, const vector3&);
						vector3 cross(const vector3&) const;
						m_real distance(const vector3& other) const;
						void normalize();
						void multadd(const vector3&, m_real);	
						m_real length() const;
						void interpolate( m_real, vector3 const&, vector3 const& );
						void difference(vector3 const& v1, vector3 const& v2);
						void rotate( const quater& q);
						void rotate( const quater& q, vector3 const& in);
						void rotationVector(const quater& in);
						]],
						{'void add(const vector3&);', rename='radd'},
						{'void sub(const vector3&);', rename='rsub'},
						{'void operator=(const vector3&);', rename='assign'},
					},
				},
				{
					name='quater', --necessary
					properties={'double x', 'double y', 'double z', 'double w'},
					ctors=
					{
						[[
								()
								(double,double,double,double)
								(double, vector3 const&)
						]]
					},
					wrapperCode=
					[[
								static vector3 rotate(quater const& q, vector3 const& v)
								{
									vector3 out;
									out.rotate(q,v);
									return out;
								}
								static void setRotation(quater &q, const char* aChannel, vector3 & euler)
								{
									q.setRotation(aChannel, euler);
								}
								static void getRotation(quater const&q, const char* aChannel, vector3 & euler)
								{
									q.getRotation(aChannel, euler);
								}
								static vector3 getRotation(quater const&q, const char* aChannel)
								{
									vector3 euler;
									q.getRotation(aChannel, euler);
									return euler;
								}
								]],
					staticMemberFunctions={
						[[
								static vector3 rotate(quater const& q, vector3 const& v)
								static void setRotation(quater &q, const char* aChannel, vector3 & euler)
								static void getRotation(quater const&q, const char* aChannel, vector3 & euler)
								static vector3 getRotation(quater const&q, const char* aChannel)
						]]
					},
					memberFunctions={
						[[
								void slerp( quater const&, quater const&, m_real );
								void safeSlerp( quater const&, quater const&, m_real );// align이 안되어 있어도 동작
								void interpolate( m_real, quater const&, quater const& );
								void setAxisRotation(const vector3& vecAxis, const vector3& front, const vector3& vecTarget);
								void identity()
								quater   inverse() const
								void decompose(quater& rotAxis_y, quater& offset) const;
								void decomposeTwistTimesNoTwist (const vector3& rkAxis, quater& rkTwist, quater& rkNoTwist) const;
								void decomposeNoTwistTimesTwist (const vector3& rkAxis, quater& rkNoTwist, quater& rkTwist) const;
								void difference(quater const& q1, quater const& q2);			//!< quaternion representation of "angular velocity w" : q2*inv(q1);
								void scale(m_real s);
								void mult(quater const& a, quater const& b);// cross product
								quater    operator+( quater const& b) const		
								quater    operator-( quater const& b) const		
								quater    operator-() const						
								quater    operator*( quater const& b) const		
								quater    operator*( m_real b) const			
								vector3	  operator*(vector3 const& b) const		
								quater    operator/( m_real b) const			
								m_real  length() const;
								m_real rotationAngle() const	
								m_real rotationAngleAboutAxis(const vector3& axis) const;
								vector3 rotationVector() const
								void operator=(quater const& a)
								void operator=(quater const& a) @set
								void setValue( m_real ww,m_real xx, m_real yy, m_real zz )
								void axisToAxis( const vector3& vFrom, const vector3& vTo);
								void leftMult(quater const& a)			
								void rightMult(quater const& a)			
								void setRotation(const vector3&, m_real)
								void setRotation(const vector3& )
								void setRotation(const matrix4& a)
								void normalize();
								void align(const quater& other)
								TString output(); @ __tostring
						]]
					},
				},
			},
			modules={
				{
					namespace='_G' -- global
				},
				{
					namespace='Imp',
					enums={
						{"LINE_CHART", "(int)Imp::LINE_CHART"},
						{"BAR_CHART", "(int)Imp::BAR_CHART"},
					},
					functions={[[
					CImage* Imp::DrawChart(const vectorn& vector, int chart_type);
					CImage* Imp::DrawChart(const matrixn& matrix, int chart_type);
					void Imp::ChangeChartPrecision(int precision);
					void Imp::DefaultPrecision();
					]]}
				},
				{
					namespace='util',
					decl=[[
					#include <stdio.h>
					#include <termios.h>
					#include <unistd.h>
					]],
					wrapperCode=[[
					 
					static int getch( ) {
					  struct termios oldt,
									 newt;
					  int            ch;
					  tcgetattr( STDIN_FILENO, &oldt );
					  newt = oldt;
					  newt.c_lflag &= ~( ICANON | ECHO );
					  tcsetattr( STDIN_FILENO, TCSANOW, &newt );
					  ch = getchar();
					  tcsetattr( STDIN_FILENO, TCSANOW, &oldt );
					  return ch;
					}
					static void putch(const char* str ) {
						printf("%s",str);
						fflush(stdout);
					}
					]],
					functions ={[[
									  void OutputToFile(const char* filename, const char* string); @ outputToFile
									  int getch( ) 
									  void putch(const char* str)
						  ]]}
				},
				{
					namespace='math',
					wrapperCode=
					[[
					static int frexp(lua_State* L)
					{
						double d=lua_tonumber(L,1);
						double f;
						int e;
						f=::frexp(d,&e);
						lua_pushnumber(L,f);
						lua_pushnumber(L,e);
						return 2;
					}
						static void filter(matrixn &c, int kernelSize)
					{
						vectorn kernel;
						Filter::GetGaussFilter(kernelSize, kernel);
						Filter::LTIFilter(1,kernel, c); 
					}
					static void filterQuat(matrixn &c, int kernelSize)
					{
						vectorn kernel;
						Filter::GetGaussFilter(kernelSize, kernel);
						Filter::LTIFilterQuat(1,kernel, c); 
					}

					static void changeChartPrecision(int precision)
					{
						Imp::ChangeChartPrecision(precision);
					}

					static void defaultPrecision()
					{
						Imp::DefaultPrecision();
					}

					static void projectAngle(m_real& delta)	// represent angle in [-pi, pi]
					{	
						while(delta>M_PI+FERR)
							delta-=2.0*M_PI;
						while(delta<-1.0*M_PI-FERR)
							delta+=2.0*M_PI;
					}

					static void alignAngle(m_real prev, m_real& next)
					{

						// next-prev는 [-PI,PI]에 있다고 보장을 못한다. 따라서 이범위에 들어오는 next-prev를 구한다.

						m_real delta=next-prev;

						projectAngle(delta);

						// 다시 원래의 prev범위로 되돌린다.
						next=prev+delta;
					}
					static void alignAngles(vectorn & value, m_real x=0)
					{
						alignAngle(x, value(0));
						for(int i=1; i<value.size(); i++)
							alignAngle(value(i-1), value(i));
					}

					static void _throwTest()
					{
						throw std::runtime_error("_throwTest");

					}
					]],
					customFunctionsToRegister ={'frexp'},
					functions=
					{
						{'int ::Hash(const char* string);',rename='Hash'},
						{'void Filter::gaussFilter(int kernelsize, matrixn& inout);',rename='gaussFilter'},
						{'void Filter::gaussFilter(int kernelsize, vectorn& inout);',rename='gaussFilter'},
						{'int Filter::CalcKernelSize(float time, float frameTime);',rename='calcKernelSize'},
						[[
						static void filter(matrixn &c, int kernelSize)
						static void filterQuat(matrixn &c, int kernelSize)
						static void changeChartPrecision(int precision)
						static void defaultPrecision()
						static void alignAngles(vectorn & value, m_real x)
						static void alignAngles(vectorn & value)
						static void _throwTest()
						]]
					}

					--[[module(L , "math")
					[
					def("Hash", &Hash),
					class_<FuncWrapper>("Function")
					.def(constructor<>())
					.def("getInout", &FuncWrapper::getInout)
					.def("func", &FuncWrapper::func)
					.def("func", &FuncWrapper::func_dfunc)
					.def("info", &FuncWrapper::info),
					class_<GSLsolver>("GSLsolver")
					.def(constructor<FuncWrapper*, const char*>())
					.def("solve", &GSLsolver::solve),
					class_<CMAwrap>("CMAwrap")
					.def(constructor<vectorn const&, vectorn const&,int,int>())
					.def("testForTermination",&CMAwrap::testForTermination)
					.def("samplePopulation",&CMAwrap::samplePopulation)
					.def("numPopulation",&CMAwrap::numPopulation)
					.def("dim",&CMAwrap::dim)
					.def("getPopulation",&CMAwrap::getPopulation)
					.def("setVal",&CMAwrap::setVal)
					.def("resampleSingle",&CMAwrap::resampleSingle)
					.def("update",&CMAwrap::update)
					.def("getMean",&CMAwrap::getMean)
					.def("getBest",&CMAwrap::getBest)
					];
					]]
				}
			},
		}

				require('luna_mainlib')
				--			require('luna_physics')
	-- namespaces can be defined here or using nested name (name='test.vector3') 
	namespaces={
		util={},
		math={},
		Ogre={}
	}

	-- definitions should be in a single lua file (Though, of couse, you can use "dofile" or "require" in this file. )
	-- output cpp files can be seperated by modules or classes so that C++ compilation time is reduced.

	function generateBaseLib()
		-- declaration
		write([[
					class CPixelRGB8;
					class TRect;
					class CImage;
					  class boolNView;
					  class boolN;
					  class NonuniformSpline;
					  class LMat;
					  class LMatView;
					  class LVec;
					  class LVecView;
					  class QPerformanceTimerCount2;
					  class FractionTimer;
					  class BSpline;
					  class intIntervals;
]])
		writeHeader(bindTarget)
		if gen_lua.use_profiler then
			write('\n#define LUNA_GEN_PROFILER\n')
		end
		flushWritten(	source_path..'/generated/luna_baselib.h')
		write(
		[[
		#include "stdafx.h"
		//#include "../BaseLib/utility/TWord.h"
		#include "../../BaseLib/motion/Motion.h"
		#include "../../BaseLib/motion/MotionLoader.h"
		#include "../MainLib/OgreFltk/MotionPanel.h"
		#include "../BaseLib/image/Image.h"
		#include "../BaseLib/image/ImageProcessor.h"
		#include "../BaseLib/motion/MotionRetarget.h"
		//#include "../BaseLib/motion/Concat.h"
		//#include "../BaseLib/motion/MotionUtilSkeleton.h"
		#include "../BaseLib/motion/MotionUtil.h"
		#include "../BaseLib/motion/ConstraintMarking.h"
		#include "../BaseLib/motion/postureip.h"
		#include "../BaseLib/math/Operator.h"
		#include "../BaseLib/math/Operator_NR.h"
		#include "../../BaseLib/math/bitVectorN.h"
		//#include "../BaseLib/math/GnuPlot.h"
		#include "../BaseLib/math/conversion.h"
		//#include "../BaseLib/math/stransf.h"
		#include "../BaseLib/math/Filter.h"
		#include "../BaseLib/math/matrix3.h"
		//#include "../BaseLib/math/BSpline.h"
		//#include "../BaseLib/math/LMat.h"
		//#include "../BaseLib/math/LVec.h"
		//#include "../BaseLib/math/LMat_lapack.h"
		#include "../BaseLib/utility/operatorString.h"
		#include "../BaseLib/utility/QPerformanceTimer.h"
		#include "../BaseLib/utility/tfile.h"
		//#include "../BaseLib/math/GnuPlot.h"
		//		#include "../MainLib/WrapperLua/BaselibLUA2.h"
				
		]]
		)
		writeIncludeBlock(true)
		write('#include "luna_baselib.h"')
		writeDefinitions(bindTarget, 'Register_baselib') -- input bindTarget can be non-overlapping subset of entire bindTarget 
		flushWritten(source_path..'/generated/luna_baselib.cpp') -- write to cpp file only when there exist modifications -> no-recompile.
	end
	function generate() 
		buildDefinitionDB(bindTarget, bindTargetMainLib)--, bindTargetPhysics) -- input has to contain all classes to be exported.
		-- write function can be used liberally.
		generateBaseLib()
		generateMainLib()
		--generatePhysicsBind()
		writeDefinitionDBtoFile(source_path..'/generated/luna_baselib_db.lua')
	end
