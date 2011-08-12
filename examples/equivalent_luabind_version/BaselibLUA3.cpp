
#include "stdafx.h"
#include "BaselibLUA.h"
#include "BaselibLUA2.h"
#include "../OgreFltk/MotionPanel.h"
#include "../BaseLib/motion/MotionRetarget.h"
#include "../BaseLib/motion/Concat.h"
#include "../BaseLib/motion/MotionUtilSkeleton.h"
#include "../BaseLib/motion/MotionUtil.h"
#include "../BaseLib/motion/MotionDOF.h"
#include "../BaseLib/motion/ASFLoader.h"
#include "../BaseLib/math/Operator.h"
#include "../BaseLib/math/OperatorStitch.h"
#include "../BaseLib/math/GnuPlot.h"
#include "../BaseLib/math/conversion.h"
#include "../BaseLib/math/intervals.h"
#include "../OgreFltk/MotionManager.h"
#include "../BaseLib/motion/VRMLexporter.h"
#include "../BaseLib/motion/FullbodyIK.h"
#include "../BaseLib/motion/FullbodyIK_MotionDOF.h"
#include "../BaseLib/motion/ASFLoader.h"
#include "../BaseLib/motion/BVHLoader.h"
#include "../BaseLib/motion/Vloader/VLoader.h"
#include "../MainLib/MotionSynthesis/ParseGrcFile.h"
#include <luabind/luabind.hpp>
#include <luabind/operator.hpp>
#include <luabind/object.hpp>
#include <luabind/out_value_policy.hpp>
#include <luabind/return_reference_to_policy.hpp>
#include <luabind/copy_policy.hpp>
#include <luabind/adopt_policy.hpp>
#include <luabind/discard_result_policy.hpp>
#include <luabind/dependency_policy.hpp>
#include <luabind/luabind.hpp>

void quaterNN_linstitch(m2::_op const& op, matrixn& c, matrixn & a, matrixn & b);

using namespace luabind;


namespace MotionUtil
{
  void insertBalanceJoint(MotionLoader& skel);
  void retargetEntireMotion(Motion& source, bool bRetargetFoot=true, bool bRetargetArm=true);
  
}

void addBaselibModule2(lua_State* L)
{
  // quaterN
  {
    struct quaterN_
    {
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
      
      static quaterNView range(quaterN & in, int start, int end)
      {
	return in.range(start,end);
      }
    };
    
    quater& (quaterN::*row2)(int) const=&quaterN::row;
    void (quaterN::*assign1)(const quaterN& other)=&quaterN::assign;
    module(L)[
	      class_<quaterN>("quaterN")
	      .def(constructor<>())
	      .def(constructor<int>())
	      //.def("value", &quaterN::value, dependency(result, _1))
	      .def("row", (quater& (quaterN::*)(int) const)(&quaterN::row))
	      .def("rows", (int (quaterN::*)() const)(&quaterN::row))
	      .def("size", &quaterN::size)
	      .def("setSize", &quaterN::setSize)
	      .def("resize", &quaterN::resize)
	      .def("sampleRow", &quaterN_::sampleRow)
	      .def("range", &quaterN::range)
	      .def("range", &quaterN_::range)
	      .def("assign", (void (quaterN::*)(const quaterN& other))&quaterN::assign)
	      .def("at", &quaterN::value)
	      .def("matView", (matrixnView (*)(quaterN const& a, int start, int end))&matView)
	      .def("__call", &quaterN::value)
		  .def("transition", &quaterN::transition)
	      

	      ,class_<quaterNView, quaterN >("quaterNView")
	      ];
    
  }
  
  
  // vector3N
  {
    void (vector3N::*assign1)(const vector3N& other)=&vector3N::assign;
    struct vector3N_
    {
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
      
      static vector3NView range(vector3N & in, int start, int end)
      {
	return in.range(start,end);
      }

	  static vector3N __add(vector3N const&a, vector3N const&b)
	  {
		  vector3N c;
		  c.add(a,b);
		  return c;
	  }
	  static vector3N __sub(vector3N const&a, vector3N const&b)
	  {
		  vector3N c;
		  c.sub(a,b);
		  return c;
	  }
    };
    module(L)[
	      class_<vector3N>("vector3N")
	      .def(constructor<>())
	      .def(constructor<int>())
	      
	      .def("value", &vector3N::value)
	      .def("at", &vector3N::value)
	      .def("__call", &vector3N::value)
	      .def("__mul", &vector3N::operator*)
		  .def("__add", &vector3N_::__add)
		  .def("__sub", &vector3N_::__sub)
	      .def("rows", &vector3N::rows)
	      .def("row", &vector3N::row)
	      .def("setAllValue", (void (vector3N::*)(vector3))&vector3N::setAllValue)
	      .def("size", &vector3N::size)
	      .def("range", &vector3N::range)
	      .def("range", &vector3N_::range)
	      .def("assign", assign1)
	      .def("resize", &vector3N::resize)
	      .def("setSize", &vector3N::setSize)
	      .def("transition",  &vector3N::transition)
	      .def("pushBack", &vector3N::pushBack)
	      .def("sampleRow", &vector3N_::sampleRow)
	      .def("matView", (matrixnView (*)(vector3N const& a, int start, int end))&matView)
	      .def("matView", (matrixnView (*)(vector3N const& a))&matView)
	      .def("x", &vector3N::x)
	      .def("y", &vector3N::y)
	      .def("z", &vector3N::z),
	      
	      class_<vector3NView, vector3N>("vector3NView")
	      ];
  }
  
  // intvectorn
  {
    struct intvectorn_
    {
      static void assign(intvectorn & l, object const& ll)
      {
	int count=LUAwrapper::arraySize(ll);
	
	l.setSize(count);
	for(int i=0; i<count; i++)
	  l[i]=object_cast<int>(ll[i+1]);
      }
      static void setAllValue(intvectorn & a, int b) {a.setAllValue(b);}
    
      
      static std::string output(intvectorn & q)
      {
	return std::string(q.output());
      }
      
      static intvectornView _range(intvectorn const& a, int start, int end)
      {
	int nSize;
	nSize=(end-start);
	
	int* ptr;
	int stride,n,on;
	a._getPrivate(ptr, stride, n, on) ;
	return intvectornView(ptr+start*stride, nSize, stride);
      }
      
      static int back(intvectorn const& a, int i)
      {
	return a(a.size()-1+i);
      }
    };
    
    intvectornView (intvectorn::*range)(int start, int end, int step)=&intvectorn::range;
    module(L)[
	      class_<intvectorn>("intvectorn")
	      .def(constructor<>())
	      .def(constructor<int>())
	      
	      .def("assign", &intvectorn_::assign)
	      .def("assign", (intvectorn& (intvectorn::*)(const intvectorn& ) )&intvectorn::assign)
	      .def("value", (int (intvectorn::*)( int i ) const)&intvectorn::getValue)
	      .def("get", (int (intvectorn::*)( int i ) const)&intvectorn::getValue)
	      .def("__call", (int (intvectorn::*)( int i ) const)&intvectorn::getValue)
	      .def("set", (void (intvectorn::*)( int i, int d ))&intvectorn::setValue)
	      .def("size", &intvectorn::size)
	      .def("setSize", &intvectorn::setSize)
	      .def("resize", &intvectorn::resize)
	      .def("pushBack", &intvectorn::pushBack)
	      .def("back", &intvectorn_::back)
	      .def("range", range)
	      .def("range", &intvectorn_::_range)
	      .def("__tostring", &intvectorn_::output)
	      .def("colon", &intvectorn::colon)
		  .def("setAllValue", &intvectorn_::setAllValue)
	      ,class_<intvectornView, intvectorn>("intvectornView")
	      ];
  }

  {
	  struct boolN_
	  {
		  static void assign(boolN & l, object const& ll)
		  {
			  int count=LUAwrapper::arraySize(ll);

			  l.resize(count);
			  for(int i=0; i<count; i++)
				  l.set(i, object_cast<bool>(ll[i+1]));
		  }


		  static std::string output(boolN const& q)
		  {
			  return std::string(q.output());
		  }

		  static boolNView _range(boolN const& a, int start, int end)
		  {
			  return boolNView (a._vec, a._start+start, a._start+end);
		  }
	  };
	  struct intIntervals_
	  {
		  static int start(intIntervals const& i, int iInterval)
		  { return i.start(iInterval); }
		  static int end(intIntervals const& i, int iInterval)
		  { return i.end(iInterval); }
		  static void set(intIntervals & i, int iInterval, int s, int e)
		  {
			  i.start(iInterval)=s;
			  i.end(iInterval)=e;
		  }
		  static void runLengthEncode(intIntervals & i, const boolN& source)
		  { i.runLengthEncode(source.bit()); }

	  };

    module(L)[
	      class_<boolN>("boolN")
	      .def(constructor<>())
	      .def(constructor<int>())
		  .def("bit", &boolN::bit)
	      .def("assign", &boolN_::assign)
	      .def("assign", &boolN::assign)
	      .def("__call", &boolN::operator[])
	      .def("set", &boolN::set)
		  .def("setAllValue", &boolN::setAllValue)
	      .def("size", &boolN::size)
	      .def("resize", &boolN::resize)
	      .def("range", &boolN_::_range)
	      .def("__tostring", &boolN_::output)

	      ,class_<boolNView, boolN>("boolNView")
		  ,class_<bitvectorn>("bitvectorn")
		  .def(constructor<>())
		  .def("findLocalOptimum", &bitvectorn::findLocalOptimum)
		  .def("setSize",&bitvectorn::setSize)
		  .def("size",&bitvectorn::size)
		  .def("clearAll",&bitvectorn::clearAll)
		  .def("setAll",&bitvectorn::setAll)
		  .def("set",(void(bitvectorn::*)(int, bool))(&bitvectorn::setValue))
		  .def("__call",&bitvectorn::getValue)
		  .def("save",&bitvectorn::save)
		  .def("load",&bitvectorn::load)
		  .enum_("constants") [ 
		  value("ZC_MIN", bitvectorn::ZC_MIN), value("ZC_MAX", bitvectorn::ZC_MAX), value("ZC_ALL", bitvectorn::ZC_ALL) 
		  ]
		,class_<intIntervals>("intIntervals")
			.def(constructor<>())
			.def("numInterval", &intIntervals::numInterval)
		  .def("size", &intIntervals::size)
		  .def("setSize", &intIntervals::setSize)
		  .def("resize", &intIntervals::resize)
		  .def("removeInterval", &intIntervals::removeInterval)
		  .def("startI", &intIntervals_::start)
		  .def("endI", &intIntervals_::end)
		  .def("set", &intIntervals_::set)
		  .def("load", &intIntervals::load)
		  .def("pushBack", &intIntervals::pushBack)
		  .def("findOverlap", &intIntervals::findOverlap)
		  .def("runLengthEncode", &intIntervals_::runLengthEncode)
	      ];
  }
  
  // namespace sop
  module(L, "sop")[
		   def("map", &sop::map)
		   ,def("clampMap", &sop::clampMap)
		   ];
  
  // namespace m2
  module(L, "m2")[
		  def("quaterNN_linstitch", &quaterNN_linstitch),
		  class_<m2::_op>("_op")
		  .def("__call", &m2::_op::calc),
		  class_<m2::c1stitchPreprocess, m2::_op>("c1stitchPreprocess")
		  .def(constructor<int, int, double, bool>()),
		  class_<m2::c1stitchPreprocessOnline, m2::_op>("c1stitchPreprocessOnline")
		  .def(constructor<int, int, double>()),
		  class_<m2::c0stitch, m2::_op>("c0stitch")
		  .def(constructor<>()),
		  class_<m2::c0stitchOnline, m2::_op>("c0stitchOnline")
		  .def(constructor<>()),
		  class_<m2::c0concat, m2::_op>("c0concat")
		  .def(constructor<>())	
		  ];
  
  // vectorn
  //{
  struct vectorn_wrap
  {
    
    static void clamp(vectorn& l, m_real a, m_real b)
    {
      for(int i=0; i<l.size(); i++)
      {
	if(l[i]<a) l[i]=a;
	else if(l[i]>b) l[i]=b;
      }
    }
    static void clamp2(vectorn& l, vectorn const& a, vectorn const& b)
    {
      for(int i=0; i<l.size(); i++)
      {
	if(l[i]<a[i]) l[i]=a[i];
	else if(l[i]>b[i]) l[i]=b[i];
      }
    }
    
    static void assign(vectorn& l, object const& ll)
    {
      int count=LUAwrapper::arraySize(ll);
      
      l.setSize(count);
      for(int i=0; i<count; i++)
	l[i]=object_cast<double>(ll[i+1]);	// lua indexing starts from 1.
    }
    static std::string out(vectorn const& v)
    {
      return std::string(v.output());
    }
    
    static m_real get(vectorn const& a, int index)
    {
      return a[index];
    }
    static vectorn __mul(vectorn const& a, m_real b)
    {vectorn c;c.mult(a,b);return c;}
    static vectorn __mul2(m_real b, vectorn const& a)
    {vectorn c;c.mult(a,b);return c;}
    
    static vectorn __div(vectorn const& a, m_real b)
    {
      vectorn c;
      c.mult(a,1.0/b);
      return c;
    }
    
    static vectorn __add(vectorn const& a, vectorn const& b)
    {vectorn c;c.add(a,b);return c;}
    
    static vectorn __sub(vectorn const& a, vectorn const& b)
    {vectorn c;c.sub(a,b);return c;}
    
    static void radd(vectorn & a, m_real b)	{a+=b;}
    static void rsub(vectorn & a, m_real b)	{a-=b;}
    static void rdiv(vectorn & a, m_real b) {a/=b;}
    static void rmult(vectorn & a, m_real b) {a*=b;}
    static void rmult2(vectorn & a, vectorn const&b) {for(int i=0; i<a.size(); i++) a[i]*=b[i];}
    static void setAllValue(vectorn & a, m_real b) {a.setAllValue(b);}
    static void radd2(vectorn & a, vectorn const& b)	{a+=b;}
    static void rsub2(vectorn & a, vectorn const& b)	{a-=b;}
    //static void rdiv2(vectorn & a, vectorn const& b) {a/=b;}
    //static void rmult2(vectorn & a, vectorn const& b) {a*=b;}
    static void sub(vectorn & c, vectorn const& a, vectorn const&b){c.sub(a,b);}
    static void add(vectorn & c, vectorn const& a, vectorn const&b){c.add(a,b);}
    
    static void smoothTransition(vectorn &c, m_real s, m_real e, int size)
    {
      c.setSize(size);
      for(int i=0; i<size; i++)
	{
	  m_real sv=sop::map(i, 0, size-1, 0,1);
	  c[i]=sop::map(sop::smoothTransition(sv), 0,1, s, e);
	}
    }
    static vectornView _range(vectorn const& a, int start, int end)
    {
      int nSize;
      nSize=(end-start);
      
      m_real* ptr;
      int stride,n,on;
      a._getPrivate(ptr, stride, n, on) ;
      return vectornView(ptr+start*stride, nSize, stride);
    }
    
  };
  
  {
    
    void (vectorn::*setValue1)( int i, m_real d )=&vectorn::setValue;
    m_real (vectorn::*getValue1)( int i ) const=&vectorn::getValue;
    vectornView (vectorn::*range)(int start, int end, int step)=&vectorn::range;
    module(L)[
	      class_<vectorn>("vectorn")
	      .def(constructor<>())
	      .def(constructor<int>())
	      .def("assign", &vectorn_wrap::assign)
	      .def("assign", (vectorn& (vectorn::*)(const vectorn& ) )&vectorn::assign, discard_result)
	      .def("assignv", (vectorn& (vectorn::*)(const vector3& ))&vectorn::assign, discard_result)
	      .def("assignq", (vectorn& (vectorn::*)(const quater& ))&vectorn::assign, discard_result)
	      .def("minimum", (m_real (vectorn::*)() const )&vectorn::minimum)
	      .def("maximum", (m_real (vectorn::*)() const )&vectorn::maximum)
	   
	      .def("sample", &v::sample)
		  .def("interpolate", &v::interpolate)
	      .def("value", getValue1)
	      .def("setAllValue", &vectorn_wrap::setAllValue)
	      .def("get", &vectorn_wrap::get)
	      .def("__call", &vectorn_wrap::get)
	      .def("radd", &vectorn_wrap::radd)
	      .def("rsub", &vectorn_wrap::rsub)
	      .def("rmult", &vectorn_wrap::rmult)
	      .def("rmult", &vectorn_wrap::rmult2)
	      .def("rdiv", &vectorn_wrap::rdiv)
	      .def("radd", &vectorn_wrap::radd2)
	      .def("rsub", &vectorn_wrap::rsub2)
	      .def("matView", (matrixnView (*)(vectorn const& a, int start, int end))&matView)
	      .def("matView", (matrixnView (*)(vectorn const& a, int col))&matView)
	      .def("vec3View", (vector3NView (*)(vectorn const&))&vec3View)
	      .def("quatView", (quaterNView (*)(vectorn const&))&quatView)
	      .def("sub", &vectorn_wrap::sub)
	      .def("add", &vectorn_wrap::add)
	      .def("toQuater", &vectorn::toQuater)
	      .def("toVector3", &vectorn::toVector3)
		  .def("setVec3", &vectorn::setVec3)
		  .def("setQuater", &vectorn::setQuater)
	      .def("pushBack", &vectorn::pushBack)
	      //.def("add", &_tvectorn<m_real>::add)
	      //.def("rmult", &vectorn_wrap::rmult2)
	      //.def("rdiv", &vectorn_wrap::rdiv2)
	      .def("set", setValue1)
	      .def("size", &vectorn::size)
	      .def("setSize", &vectorn::setSize)
	      .def("resize", &vectorn::resize)
	      .def("range", &vectorn_wrap::_range)
	      .def("length", &vectorn::length)
	      .def("sum", &vectorn::sum)
	      .def("squareSum", &vectorn::squareSum)
	      .def("avg", &vectorn::avg)
	      .def("argMin", &vectorn::argMin)
	      .def("argMax", &vectorn::argMax)
	      .def("__tostring", &vectorn_wrap::out)
	      .def("argNearest", &vectorn::argNearest)
	      .def("colon", &vectorn::colon)
	      .def("uniform", &vectorn::uniform)
	      .def("linspace", &vectorn::linspace)
	      .def("smoothTransition", &vectorn_wrap::smoothTransition)
	      .def("row", &vectorn::row)
	      .def("column", &vectorn::column)
	      //.def("normalize", &vectorn::normalize, return_value_policy<reference_existing_object>())
	      .def("negate", &vectorn::negate)
	      .def(-self) // neg (unary minus)
	      //.def("__add", &vectorn_wrap::__add)
	      //.def("__sub", &vectorn_wrap::__sub)
	      .def(self * self) // mul
		  .def(self+self)
		  .def(self-self)
	      .def("__mul", &vectorn_wrap::__mul)
	      .def("__mul", &vectorn_wrap::__mul2)
	      .def("__div", &vectorn_wrap::__div)
	      .def("clamp", &vectorn_wrap::clamp)
	      .def("clamp", &vectorn_wrap::clamp2)
	      ,class_<vectornView, vectorn>("vectornView")
	      ];
  }
  // matrixn
  {
    
    struct matrixn_
    {
      static void assign(matrixn& l, object const& ll)
      {
	int nrows=LUAwrapper::arraySize(ll);
	
	int ncols=-1;
	for(int i=0; i<nrows; i++)
	  {
	    object const& ll_i=ll[i+1];
	    
	    if(ncols==-1)
	      ncols=LUAwrapper::arraySize(ll_i);
	    else
	      {
		if(ncols!=LUAwrapper::arraySize(ll_i))
		  throw std::range_error("ncols do not match");
	      }
	  }
	
	l.setSize(nrows, ncols);
	for(int i=0; i<nrows; i++)
	  vectorn_wrap::assign(l.row(i).lval(), ll[i+1]);
      }
      
      static void setValue(matrixn& l, object const& ll)
      {
	int nval=LUAwrapper::arraySize(ll);
	
	if(nval!=l.rows()*l.cols()) throw std::runtime_error("matrixn_::setValue");
	
	int c=1;
	for(int i=0; i<l.rows(); i++)
	  {
	    for(int j=0; j<l.cols(); j++)
	      {
		l[i][j]=object_cast<double>(ll[c++]);
	      }
	  }
      }
      
		static void mult(matrixn &c, matrixn const& a, matrixn const& b)
		{
			c.mult(a,b);
		}
		static void multABt(matrixn &c, matrixn const& a, matrixn const& b)
		{
			c.multABt(a,b);
		}
		static void multAtB(matrixn &c, matrixn const& a, matrixn const& b)
		{
			c.multAtB(a,b);
		}
		static void multAtBt(matrixn &c, matrixn const& a, matrixn const& b)
		{
			c.multAtBt(a,b);
		}
      
      static matrixn __mul(matrixn const& a, m_real b)
      {matrixn c;c.mult(a,b);return c;}
      static matrixn __mul2(m_real b, matrixn const& a)
      {matrixn c;c.mult(a,b);return c;}
      
      static matrixn __add(matrixn const& a, m_real b)
      {matrixn c;c.add(a,b);return c;}
      static matrixn __add2(m_real b, matrixn const& a)
      {matrixn c;c.add(a,b);return c;}
      
      static matrixn __div(matrixn const& a, m_real b)
      {
	matrixn c;
	c.mult(a,1.0/b);
	return c;
      }
      
      //static void radd(matrixn & a, m_real b)	{a+=b;}
      //static void rsub(matrixn & a, m_real b)	{a-=b;}
      static void rdiv(matrixn & a, m_real b) {a/=b;}
      static void rmult(matrixn & a, m_real b) {a*=b;}
      static void setAllValue(matrixn & a, m_real b) {a.setAllValue(b);}
      static void radd2(matrixn & a, matrixn const& b)	{a+=b;}
      static void rsub2(matrixn & a, matrixn const& b)	{a-=b;}
      
      static void draw(matrixn& mat, const char* filename) {mat.op0(m0::draw(filename));}
      static void draw2(matrixn& mat, const char* filename, float fMin, float fMax)
      {mat.op0(m0::draw(filename, fMin, fMax));}
      static void pushBack(matrixn& mat, const vectorn& v) { mat.pushBack(v);}
      static std::string output(matrixn & q)
      {
	return std::string(q.output("%g"));
      }
      
      static void transpose(matrixn& a)
      {
	matrixn c;
	c.transpose(a);
	a=c;
      }
		static void transpose2(matrixn& a, matrixn const& b)
      {
		  a.transpose(b);
      }
      
	  static void inverse(matrixn &out, matrixn const& input)
	  {
		  out.inverse(input);
	  }

      static void sampleRow(matrixn const& in, m_real criticalTime, vectorn& out)
      {
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
	else
	  {
	    if(a<0)
	      v2::interpolate(t-1.0).calc(out, in.row(a+1), in.row(a+2));
	    else if(a+1>=in.rows())
	      v2::interpolate(t+1.0).calc(out, in.row(a-1), in.row(a));
	    else
	      v2::interpolate(t).calc(out, in.row(a), in.row(a+1));
	  }
      }
      static void drawSignals(matrixn & in, const char* filename,  bool useTheSameMinMax)
      {
	m0::drawSignals(filename,useTheSameMinMax).calc(in);
      }
    };
    quater& (quaterN::*row2)(int) const=&quaterN::row;
    void (quaterN::*assign1)(const quaterN& other)=&quaterN::assign;
    module(L)[
	      class_<matrixn>("matrixn")
	      .def(constructor<>())
	      .def(constructor<int,int>())
	      //.def("radd", &matrixn_::radd)
	      //.def("rsub", &matrixn_::rsub)
	      .def("rmult", &matrixn_::rmult)
	      .def("rdiv", &matrixn_::rdiv)
	      .def("radd", &matrixn_::radd2)
	      .def("rsub", &matrixn_::rsub2)
		  .def("mult", &matrixn_::mult)
		  .def("multABt", &matrixn_::multABt)
		  .def("multAtB", &matrixn_::multAtB)
		  .def("multAtBt", &matrixn_::multAtBt)
	      .def("value", (m_real (matrixn::*)( int, int))&matrixn::getValue)
	      .def("setValue", &matrixn_::setValue)
	      .def("get", (m_real (matrixn::*)( int, int))&matrixn::getValue)
	      .def("__call", (m_real (matrixn::*)( int, int))&matrixn::getValue)
	      .def("set", (void (matrixn::*)( int, int, m_real))&matrixn::setValue)
	      .def("rows", &matrixn::rows)
	      .def("cols", &matrixn::cols)
	      .def("row", &matrixn::row)
	      .def("column", &matrixn::column)
	      .def("diag", &matrixn::diag)
	      .def("transpose", &matrixn_::transpose)
	      .def("transpose", &matrixn_::transpose2)
	      .def("matViewCol", (matrixnView (*)(matrixn const& a, int startCol, int endCol))&matViewCol)
	      .def("matViewRow", (matrixnView (*)(matrixn const& a, int startRow, int endRow))&matView)
	      .def("vec3ViewCol", (vector3NView (*)(matrixn const& a, int startCol))&vec3ViewCol)
	      .def("quatViewCol", (quaterNView (*)(matrixn const& a, int startCol))&quatViewCol)
	      .def("assign", (matrixn&  (matrixn::*)( matrixn const& ))&matrixn::assign, discard_result)
	      .def("pseudoInverse", &matrixn::pseudoInverse, discard_result)
	      .def("assign", &matrixn_::assign)
	      .def("setSize", &matrixn::setSize)
	      .def("resize", &matrixn::resize)
	      .def("__tostring", &matrixn_::output)
	      .def("setAllValue", (void	(matrixn::*)(m_real))&matrixn::setAllValue)
	      .def("range", (matrixnView (matrixn::*)(int, int, int, int))&matrixn::range)
	      .def("minimum", &matrixn::minimum)
	      .def("maximum", &matrixn::maximum)
	      .def("sum", &matrixn::sum)
	      .def("pushBack", &matrixn_::pushBack)
	      .def("sampleRow", &matrixn_::sampleRow)
	      .def("draw", &matrixn_::draw) // draw(filename)
	      .def("draw", &matrixn_::draw2)// draw(filename, min, max)
	      .def("drawSignals", &matrixn_::drawSignals)
		  .def("inverse", &matrixn_::inverse)
	      //.def(-self) // neg (unary minus)
	      .def(self + self) // add (homogeneous)
	      .def(self - self) // add (homogeneous)
	      .def(self * self) // mul
	      .def("__mul", &matrixn_::__mul)
	      .def("__mul", &matrixn_::__mul2)
	      .def("__add", &matrixn_::__add)
	      .def("__add", &matrixn_::__add2)
	      
	      .def("__div", &matrixn_::__div)
	      ,class_<matrixnView, matrixn>("matrixnView")
	      ];
    
  }
  
  
  // Motion
  {
    struct Motion_
    {
      static void initFromFile(Motion& motion, const char* fn)
      {
	motion.Init(RE::renderer().m_pMotionManager->GetMotionLoaderPtr(fn));
      }
      
      static void initSkeletonFromFile(Motion& motion, const char* fn)
      {
	motion.InitSkeleton(RE::renderer().m_pMotionManager->GetMotionLoaderPtr(fn));
      }
      
      static void concatFromFile(Motion& motion, const char* fn)
      {
	RE::motion::concatFromFile(motion, fn);
      }
      static void scale(Motion& motion, m_real fScale)
      {
		  if (&motion.skeleton().m_cPostureIP==&motion)
			  motion.skeleton().Scale(fScale);
		  else
			  motion.skeleton().scale(fScale, motion);
      }
      static void CalcInterFrameDifference(Motion& motion)
      {
	motion.CalcInterFrameDifference(0);
      }
      
      static void translate(Motion& motion, vector3 const& t)
      {
	MotionUtil::translate(motion, t);
      }
      
      static void InitEmpty(Motion& motion, MotionLoader* pSkel, int numFrame)
      {
	motion.InitEmpty(pSkel, numFrame);
      }
      
      static void smooth(Motion& motion, float kernelRoot, float kernelJoint)
      {
	Motion copy=motion;
	MotionUtil::smooth(motion, copy, kernelRoot, kernelJoint);
      }
    };
    //void (Motion::*initEmpty1)(MotionLoader*, int) =&Motion::InitEmpty;
    void (Motion::*init1)(const Motion&, int, int) =&Motion::Init;
    int (Motion::*numFrames1) () const=&Motion::numFrames;
    
    module(L)[
	      class_<Motion>("Motion")
	      .def(constructor<MotionLoader*>())
	      .def(constructor<const Motion&, int, int>())
	      .def("length",&Motion::length)	// 동작 길이
	      .def("changeLength", &Motion::changeLength)
	      .def("numFrames", numFrames1)  // 프레임 개수 =동작길이 +1
	      .def("resize", &Motion::Resize)
	      .def("skeleton", &Motion::skeleton)// MotionLoader리턴
	      .def("setSkeleton", &Motion::setSkeleton) // mot.setSkeleton(12) mot.skeleton().
	      .def("setPose", &Motion::setPose)
	      .def("empty", &Motion::empty)
	      //.def("setMaxCapacity", &Motion::setMaxCapacity)
	      .def("initEmpty", &Motion_::InitEmpty)
	      .def("init", init1)
	      .def("init", (void (Motion::*)(MotionLoader* pSource) )&Motion::Init)
	      .def("initSkeleton", (void (Motion::*)(MotionLoader* pSource) )&Motion::InitSkeleton)
	      .def("initSkeletonFromFile", &Motion_::initSkeletonFromFile)
	      .def("initFromFile", &Motion_::initFromFile)
	      .def("concatFromFile", &Motion_::concatFromFile)
	      .def("scale", &Motion_::scale)
	      .def("setIdentifier", &Motion::SetIdentifier)
	      .def("getIdentifier", &Motion::GetIdentifier)
	      .def("range", (MotionView (Motion::*)(int , int , int ))&Motion::range)
	      .def("exportMot", &Motion::exportMOT)
	      .def("samplePose",&Motion::samplePose)
		  .def("isConstraint", (bool (Motion::*)(int fr, int eConstraint) const)&Motion::isConstraint)
		  .def("setConstraint", &Motion::setConstraint)
	      .def("concat", &Motion::Concat)	// to handle default arguments
	      .def("numRotJoint", &Motion::NumJoints)
	      .def("numTransJoint", &Motion::numTransJoints)
	      .def("totalTime", &Motion::totalTime)
	      .def("frameRate", &Motion::frameRate)
		  .def("setFrameTime", (void (Motion::*)(float ftime))&Motion::frameTime)
	      .def("kernelSize", &Motion::KernelSize)
	      .def("isDiscontinuous", &Motion::isDiscontinuous)
	      .def("setDiscontinuity", (void (Motion::*)(int fr, bool value))&Motion::setDiscontinuity)
	      .def("pose", &Motion::pose)
	      .def("calcInterFrameDifference",&Motion::CalcInterFrameDifference)
	      .def("calcInterFrameDifference",&Motion_::CalcInterFrameDifference)
	      .def("reconstructFromInterFrameDifference", &Motion::ReconstructDataByDifference)
	      .def("translate", &Motion_::translate)
	      .def("smooth", &Motion_::smooth),
	      class_<MotionView, Motion>("MotionView")
	      ];
    
    module(L, "MotionUtil")[
			    def("noiseReduction", &MotionUtil::noiseReduction),
			    def("insertRootJoint", &MotionUtil::insertRootJoint),
				def("exportBVH", &MotionUtil::exportBVH)
			    ];
    
    module(L)[
	      class_<MotionDOF, matrixn>("MotionDOF")
	      .def(constructor<const MotionDOFinfo& >())
	      .def(constructor<const MotionDOF&>())
	      .def_readwrite("dofInfo", &MotionDOF::mInfo)
	      .def("copyFrom", &MotionDOF::operator=)
	      .def("assign", &MotionDOF::operator=)
	      .def("numFrames",&MotionDOF::numFrames)
	      .def("resize", (void (MotionDOF::*)(int))&MotionDOF::resize)
	      .def("numDOF",&MotionDOF::numDOF)
	      .def("length",&MotionDOF::length)
	      .def("matView",&MotionDOF::_matView)
	      .def("changeLength",&MotionDOF::changeLength)
	      .def("rootTransformation",(transf (MotionDOF::*)(int i) const)&MotionDOF::rootTransformation)
	      .scope
	      [
	       def("rootTransformation",(transf (*)(vectorn const& ))&MotionDOF::rootTransformation),
	       def("setRootTransformation",(void (*)(vectorn & , transf const& ))&MotionDOF::setRootTransformation)
	       ]
	      .def("set",&MotionDOF::set)
	      .def("range", &MotionDOF::range)
	      .def("range_c", &MotionDOF::range_c)
	      .def("get",&MotionDOF::get)
	      .def("samplePose",&MotionDOF::samplePose)
	      .def("stitch", &MotionDOF::stitch)
	      .def("stitchDeltaRep", &MotionDOF::stitchDeltaRep)
		  .def("__call", &MotionDOF::row)
	      .def("convertToDeltaRep", &MotionDOF::convertToDeltaRep)
	      .def("reconstructData", (void (MotionDOF::*)(vector3 const& ) )&MotionDOF::reconstructData)
	      .def("reconstructData", (void (MotionDOF::*)(vector3 const& , matrixn& ) const)&MotionDOF::reconstructData)
	      .def("reconstructData", (void (MotionDOF::*)(transf const& , matrixn& ) const)&MotionDOF::reconstructData)
	      .def("generateID",&MotionDOF::generateID)
	      .def("dv_x", &MotionDOF::dv_x)
	      .def("dv_z", &MotionDOF::dv_z)
	      .def("dq_y", &MotionDOF::dq_y)
	      .def("offset_y", &MotionDOF::offset_y),
	      class_<MotionDOFinfo>("MotionDOFinfo")
	      .def(constructor<>())
	      //.def("init", (void (MotionDOFinfo::*)(MotionLoader const&))&MotionDOFinfo::init)
	      .def("numDOF", (int (MotionDOFinfo::*)() const)&MotionDOFinfo::numDOF)
	      .def("numActualDOF",&MotionDOFinfo::numActualDOF)
	      .def("numDOF", (int (MotionDOFinfo::*)(int) const)&MotionDOFinfo::numDOF)
	      .def("DOFtype", &MotionDOFinfo::DOFtype)
	      .def("DOFindex", &MotionDOFinfo::DOFindex)
	      .def("numBone", &MotionDOFinfo::numBone)
	      .def("getDOF", &MotionDOFinfo::getDOF)
	      .def("numSphericalJoint", &MotionDOFinfo::numSphericalJoint)
	      .def("sphericalDOFindex", &MotionDOFinfo::sphericalDOFindex)
	      .def("skeleton", &MotionDOFinfo::skeleton)
	      .def("setDOF", (void (MotionDOFinfo::*)(vectorn const&, Posture&)const)&MotionDOFinfo::setDOF)
	      .def("setDOF", (Posture const& (MotionDOFinfo::*)(vectorn const&)const)&MotionDOFinfo::setDOF)
	      .def("hasTranslation", &MotionDOFinfo::hasTranslation)
	      .def("hasQuaternion", &MotionDOFinfo::hasQuaternion)
	      .def("hasAngles", &MotionDOFinfo::hasAngles)
	      .def("startT", &MotionDOFinfo::startT)
	      .def("startR", &MotionDOFinfo::startR)
	      .def("endR", &MotionDOFinfo::endR)
	      .def("frameRate", &MotionDOFinfo::frameRate)
		  .def("setFrameRate", &MotionDOFinfo::setFrameRate)
		  .def("blend",&MotionDOFinfo::blend)
		  .def("blendDelta",&MotionDOFinfo::blendDelta)
		  .def("blendBone",&MotionDOFinfo::blendBone)
	      .enum_("constants")
	      [
	       value("ROTATE", MotionDOFinfo::ROTATE),
	       value("SLIDE", MotionDOFinfo::SLIDE),
	       value("QUATERNION_W", MotionDOFinfo::QUATERNION_W),
	       value("QUATERNION_X", MotionDOFinfo::QUATERNION_X),
	       value("QUATERNION_Y", MotionDOFinfo::QUATERNION_Y),
	       value("QUATERNION_Z", MotionDOFinfo::QUATERNION_Z)
	       ]
	      ,
	      
	      class_<MotionDOFview, MotionDOF> ("MotionDOFview"),
	      class_<InterframeDifference>("InterframeDifference")
	      .def(constructor<MotionDOF const&>())
	      .def(constructor<>())
	      .def("resize", &InterframeDifference::resize)
	      .def("numFrames", &InterframeDifference::numFrames)
	      .def("initFromDeltaRep", &InterframeDifference::initFromDeltaRep)
	      .def("exportToDeltaRep", &InterframeDifference::exportToDeltaRep)
	      .def("reconstruct", &InterframeDifference::reconstruct)
	      .def_readwrite("startP", &InterframeDifference::startP)
	      .def_readwrite("dv", &InterframeDifference::dv)
	      .def_readwrite("dq", &InterframeDifference::dq)
	      .def_readwrite("offset_y", &InterframeDifference::offset_y)
	      .def_readwrite("offset_q", &InterframeDifference::offset_q)
	      ,
	      class_<InterframeDifferenceC1>("InterframeDifferenceC1")
	      .def(constructor<MotionDOF const&>())
	      .def(constructor<m_real>())
	      .def("resize", &InterframeDifferenceC1::resize)
	      .def("numFrames", &InterframeDifferenceC1::numFrames)
	      .def("initFromDeltaRep", &InterframeDifferenceC1::initFromDeltaRep)
	      .def("exportToDeltaRep", &InterframeDifferenceC1::exportToDeltaRep)
	      .def("reconstruct", &InterframeDifferenceC1::reconstruct)
	      .scope
	      [
	       def("getTransformation",(vectorn (*)(matrixn const& ,int))&InterframeDifferenceC1::getTransformation)
	       ]
	      .def_readwrite("startP", &InterframeDifferenceC1::startP)
	      .def_readwrite("startPrevP", &InterframeDifferenceC1::startPrevP)
	      .def_readwrite("dv", &InterframeDifferenceC1::dv)
	      .def_readwrite("dq", &InterframeDifferenceC1::dq)
	      .def_readwrite("offset_y", &InterframeDifferenceC1::offset_y)
	      .def_readwrite("offset_q", &InterframeDifferenceC1::offset_q)
	      .def_readwrite("offset_qy", &InterframeDifferenceC1::offset_qy)
	      ];
  }
  
  // Posture
  {
    
    void (Posture::*blend1)(const Posture&, const Posture&,m_real)=&Posture::Blend;
    
    module(L)[
	      class_<Posture>("Pose")
	      .def(constructor<>())
	      .def("init", &Posture::Init)
	      .def("identity", &Posture::identity)
	      .def("numRotJoint", &Posture::numRotJoint)
	      .def("numTransJoint",&Posture::numTransJoint)
	      .def("clone", &Posture::clone, adopt(result))
	      .def("blend", blend1)
	      .def("align", &Posture::Align)
	      .def("front",&Posture::front)
	      .def("decomposeRot",&Posture::decomposeRot)
	      .def_readwrite("translations", &Posture::m_aTranslations)
	      .def_readwrite("rotations", &Posture::m_aRotations)
	      .def_readwrite("constraint", &Posture::constraint)
	      .def_readwrite("dv", &Posture::m_dv)
	      .def_readwrite("dq", &Posture::m_dq)
	      .def_readwrite("offset_y", &Posture::m_offset_y)
	      .def_readwrite("offset_q", &Posture::m_offset_q)
	      .def_readwrite("rotAxis_y", &Posture::m_rotAxis_y)
	      ];
  }
  
  // motionloader
  {
    
    struct MotionLoaderWrapper
    {
      static void getLinks(MotionLoader& loader, intvectorn& from, intvectorn & to )
      {
	NodeStack & stack=loader.m_TreeStack;
	
	stack.Initiate();
	
	Node *src=loader.m_pTreeRoot->m_pChildHead;	// dummy노드는 사용안함.
	while(TRUE)
	  {
	    for(;src; src=src->m_pChildHead)
	      {
		Node* child;
		for(child=src->m_pChildHead; child; child=child->m_pSibling)
		  {
		    //printf("%s -> %s\n", src->NameId, child->NameId);
		    from.pushBack(loader.GetIndex(src));
		    to.pushBack(loader.GetIndex(child));
		    
		  }
		stack.Push(src);
	      }
	    stack.Pop(&src);
	    if(!src) break;
	    src=src->m_pSibling;
	  }
      }
      
      static void printHierarchy(MotionLoader& skel)
      {
	skel.GetNode(0)->printHierarchy();
      }
      
      static MotionLoader* getMotionLoader(const char* fn)
      {
	return RE::renderer().m_pMotionManager->GetMotionLoaderPtr(fn);
      }
      
      
      static void insertRootJoint(MotionLoader& skel, object const& ll)
      {
	TString method=object_cast<const char*>(ll[1]);
	
	if(method=="COM")
	  {
	    m_real kernel_size=object_cast<double>(ll[2]);
	    m_real kernel_sizeQ=object_cast<double>(ll[3]);
	    MotionUtil::insertCOMjoint(skel, kernel_size, kernel_sizeQ);
	  }
	else if(method=="Balance")
	  {
	    MotionUtil::insertBalanceJoint(skel);
	  }
	else Msg::error("unknown method %s", method.ptr());
      }
      
      static void loadAnimation(MotionLoader& skel, Motion& mot, const char* fn)
      {
				RE::motion::loadAnimation(skel, mot, fn);
			}

			static void loadAMCmotion(MotionLoader& skel, const char* filename, Motion& mot)
			{
				((ASFLoader&)skel).LoadAMC(filename, mot);
			}

			static MotionLoader* _create(const char* filename,object const& ll)
			{
				MotionLoader* l;

				TString fn(filename);
				TString ext=fn.right(3).toUpper();
				if(ext=="ASF")
				{
					l=new ASFLoader(filename);
				}
				else if(ext=="BVH")
				{
					l=new BVHLoader(filename);
				}
				else if(ext=="SKL"){
					l=new BVHLoader(fn.left(-3)+"BVH","loadSkeletonOnly");
				}
				else if(ext=="VSK"){
					l=new VLoader(fn);
				}
				else
				{
					l=new MotionLoader(filename);
				}

				Motion& mot=l->m_cPostureIP;

				int count=LUAwrapper::arraySize(ll);

				// -- pairs(
				// for(luabind::iterator i(ll), end; i!=end; ++i){
				// 	const char* motFile=luabind::object_cast<const char*>(*i);
				
				// -- ipairs(
				for(int i=0; i<count; i++){
					const char* motFile=luabind::object_cast<const char*>(ll[i+1]);

					if(mot.numFrames()==0)
						l->loadAnimation(mot, motFile);
					else
						RE::motion::concatFromFile(mot, motFile);
				}
				return l;
			}
		};

		struct BoneForwardKinematics_
		{
			static transf& local1(BoneForwardKinematics& fk, int i){ return fk._local(i);}
			static transf& local2(BoneForwardKinematics& fk, Bone& bone){ return fk._local(bone);}
			static transf& global1(BoneForwardKinematics& fk, int i){ return fk._global(i);}
			static transf& global2(BoneForwardKinematics& fk, Bone& bone){return fk._global(bone);}
		};
		module(L)[
			def("getMotionLoader", &MotionLoaderWrapper::getMotionLoader),
			class_<MotionLoader>("MotionLoader")

			.scope[def("new", &MotionLoaderWrapper::_create, luabind::adopt(luabind::result))]
			.def(constructor<const char*>())
			.def_readwrite("mMotion", &MotionLoader::m_cPostureIP)
			.def("fkSolver", &MotionLoader::fkSolver)
			.def("readJointIndex", &MotionLoader::readJointIndex)	// ee파일 읽음.
			.def("numRotJoint", &MotionLoader::numRotJoint)
			.def("numTransJoint", &MotionLoader::numTransJoint)
			.def("numBone", &MotionLoader::numBone)
			.def("setCurPoseAsInitialPose", &MotionLoader::setCurPoseAsInitialPose)
			.def("bone", &MotionLoader::bone)
			.def("setPose", &MotionLoader::setPose)
			.def("setChain", (void (MotionLoader::*)(const Posture&, int)const)&MotionLoader::setChain)
			.def("setChain", (void (MotionLoader::*)(const Posture&, Bone&)const)&MotionLoader::setChain)
			.def("getTreeIndexByName", &MotionLoader::getTreeIndexByName)
			.def("getBoneByTreeIndex", &MotionLoader::getBoneByTreeIndex)
			.def("getBoneByRotJointIndex", &MotionLoader::getBoneByRotJointIndex)
			.def("getBoneByVoca", &MotionLoader::getBoneByVoca)
			.def("getBoneByName", &MotionLoader::getBoneByName)
			.def("removeAllRedundantBones", &MotionLoader::removeAllRedundantBones)
			.def("getTreeIndexByRotJointIndex", &MotionLoader::getTreeIndexByRotJointIndex)
			.def("getTreeIndexByTransJointIndex", &MotionLoader::getTreeIndexByTransJointIndex)
			.def("getTreeIndexByVoca", &MotionLoader::getTreeIndexByVoca)
			.def("getPose", &MotionLoader::getPose)
			.def("scale", &MotionLoader::Scale)
			.def("scale", &MotionLoader::scale)
			.def("getLinks", &MotionLoaderWrapper::getLinks)
			.def("printHierarchy", &MotionLoaderWrapper::printHierarchy)
			.def("insertChildBone", &MotionLoader::insertChildBone)
			.def("insertSiteBones", &MotionLoader::insertSiteBones)
			.def("insertJoint", (void (MotionLoader::*)(Bone&, const char*))&MotionLoader::insertJoint)
			.def("insertRootJoint", &MotionLoaderWrapper::insertRootJoint)
			.def("loadAMCmotion", &MotionLoaderWrapper::loadAMCmotion)
			.def("loadAnimation", &MotionLoaderWrapper::loadAnimation)
			.def("updateBone", &MotionLoader::UpdateBone)
			.def("updateInitialBone", &MotionLoader::UpdateInitialBone)
			.def("_changeVoca", &MotionLoader::_changeVoca)
			.enum_("constants")
			[
				value("HIPS", (int)MotionLoader::HIPS),
				value("LEFTHIP", (int)MotionLoader::LEFTHIP),
				value("LEFTKNEE", (int)MotionLoader::LEFTKNEE),
				value("LEFTANKLE", (int)MotionLoader::LEFTANKLE),
				value("LEFTTOES", (int)MotionLoader::LEFTTOES),
				value("RIGHTHIP", (int)MotionLoader::RIGHTHIP),
				value("RIGHTKNEE", (int)MotionLoader::RIGHTKNEE),
				value("RIGHTANKLE", (int)MotionLoader::RIGHTANKLE),
				value("RIGHTTOES", (int)MotionLoader::RIGHTTOES),
				value("CHEST", (int)MotionLoader::CHEST),
				value("CHEST2", (int)MotionLoader::CHEST2),
				value("LEFTCOLLAR", (int)MotionLoader::LEFTCOLLAR),
				value("LEFTSHOULDER", (int)MotionLoader::LEFTSHOULDER),
				value("LEFTELBOW", (int)MotionLoader::LEFTELBOW),
				value("LEFTWRIST", (int)MotionLoader::LEFTWRIST),
				value("RIGHTCOLLAR", (int)MotionLoader::RIGHTCOLLAR),
				value("RIGHTSHOULDER", (int)MotionLoader::RIGHTSHOULDER),
				value("RIGHTELBOW", (int)MotionLoader::RIGHTELBOW),
				value("RIGHTWRIST", (int)MotionLoader::RIGHTWRIST),
				value("NECK", (int)MotionLoader::NECK),
				value("HEAD", (int)MotionLoader::HEAD)
			],
			class_<BoneForwardKinematics>("BoneForwardKinematics")
			.def(constructor<MotionLoader*>()) 
			.def("init", &BoneForwardKinematics::init)
			.def("forwardKinematics", &BoneForwardKinematics::forwardKinematics)
			.def("setPose", &BoneForwardKinematics::setPose)
			.def("setPoseDOF", &BoneForwardKinematics::setPoseDOF)
			.def("setChain", (void (BoneForwardKinematics::*)(const Posture& pose, const Bone& bone))&BoneForwardKinematics::setChain)
			.def("getPoseFromGlobal", &BoneForwardKinematics::getPoseFromGlobal)
			.def("getPoseDOFfromGlobal", &BoneForwardKinematics::getPoseDOFfromGlobal)
			.def("getPoseFromLocal", &BoneForwardKinematics::getPoseFromLocal)

			.def("localFrame", &BoneForwardKinematics_::local1)
			.def("localFrame", &BoneForwardKinematics_::local2)
			.def("globalFrame", &BoneForwardKinematics_::global1)
			.def("globalFrame", &BoneForwardKinematics_::global2),
			class_<VLoader,MotionLoader>("VLoader")
			.def_readwrite("frames", &VLoader::frames)
			.def_readwrite("markers", &VLoader::markers)
		];
	}

	// bone
	{
		struct Bone_wrapper
		{
			static bool isChildHeadValid(Bone& bone)   { return bone.m_pChildHead!=NULL;}
			static bool isChildTailValid(Bone& bone)   { return bone.m_pChildTail!=NULL;}
			static bool isSiblingValid(Bone& bone)   { return bone.m_pSibling!=NULL;}

			static Bone* childHead(Bone& bone)	{ return ((Bone*)bone.m_pChildHead);}
			static Bone* childTail(Bone& bone)	{ return ((Bone*)bone.m_pChildTail);}
			static Bone* sibling(Bone& bone)	{ return ((Bone*)bone.m_pSibling);}
			static Bone* parent(Bone& bone)	{ return bone.parent();}

			static void getTranslation(Bone& bone, vector3& trans)
			{
				bone.getTranslation(trans);
			}
			static vector3 getTranslation2(Bone& bone)
			{
				return bone.getTranslation();
			}
			static vector3 getOffset2(Bone& bone)
			{
				vector3 v;
				bone.getOffset(v);
				return v;
			}

			static void getRotation(Bone& bone, quater& q)
			{
				bone.getRotation(q);
			}
			static bool eq(Bone& bone1, Bone& bone2)
			{
				return &bone1==&bone2;
			}

			static std::string name(Bone& bone)
			{
				return std::string(bone.NameId);
			}

			static std::string getRotationalChannels(Bone& bone)
			{
				TString tt=bone.getRotationalChannels();
				if (tt.length()==0)
					return std::string("");
				return std::string(tt.ptr());
			}

			static std::string getTranslationalChannels(Bone& bone)
			{
				TString tt=bone.getTranslationalChannels();
				if (tt.length()==0)
					return std::string("");
				return std::string(tt.ptr());
			}

		};

		module(L)[
		class_<Bone> ("Bone")
			//.def_readwrite("matCombined", &Bone::m_matCombined)
			//.def_readwrite("matRotOrig", &Bone::m_matRotOrig)
			//.def_readwrite("matRot", &Bone::m_matRot)
			.def_readonly("NameId", &Bone::NameId)
			.def("name",&Bone_wrapper::name)
			.def("setName",&Bone::SetNameId)
			.def("__tostring",&Bone_wrapper::name)
			.def("getFrame", &Bone::_getFrame)
			.def("getLocalFrame", &Bone::_getLocalFrame)
			.def("length", &Bone::length)
			.def("getOffset", &Bone::getOffset)
			.def("getOffset", &Bone_wrapper::getOffset2)
			.def("getTranslation", &Bone_wrapper::getTranslation)
			.def("getTranslation", &Bone_wrapper::getTranslation2)
			.def("getRotation", &Bone_wrapper::getRotation)
			.def("childHead", &Bone_wrapper::childHead)
			.def("axis", &Bone::axis)
			.def("childTail", &Bone_wrapper::childTail)
			.def("isDescendent", &Bone::isDescendent)
			.def("parent", &Bone::parent)
			.def("sibling", &Bone_wrapper::sibling)
			.def("numChannels", &Bone::numChannels)
			.def("getRotationalChannels", &Bone_wrapper::getRotationalChannels)
			.def("getTranslationalChannels", &Bone_wrapper::getTranslationalChannels)
			.def("setChannels", &Bone::setChannels)
			.def("getOffsetTransform", &Bone::_getOffsetTransform)
			.def("getSkeleton", &Bone::getSkeleton)

			.def("voca", &Bone::voca)
			.def("rotJointIndex", &Bone::rotJointIndex)
			.def("transJointIndex", &Bone::transJointIndex)
			.def("treeIndex", &Bone::treeIndex)
			.def("parent", &Bone_wrapper::parent)

			.def("__eq", &Bone_wrapper::eq)
			.def("isChildHeadValid", &Bone_wrapper::isChildHeadValid)
			.def("isChildTailValid", &Bone_wrapper::isChildTailValid)
		.def("isSiblingValid", &Bone_wrapper::isSiblingValid)

		];
	}



	// FrameSensor
	{
		// create FrameSensor using createFrameSensor() instead of FrameSensor()
		module(L)[class_<FrameSensor>("FrameSensor")
			.def("connect", (void (FrameSensor::*) (Motion* pMotion, PLDPrimSkin* pSkin, bool bContinuous))&FrameSensor::connect)
			//.def("initAnim", &FrameSensor::InitAnim)
			.def("triggerSet", &FrameSensor::triggerSet)
		];
	}

	// MotionUtil

	{
		struct FIK_
		{
			static void init(MotionUtil::Effector& e, Bone* bone, vector3 const& l)
			{
				e.bone=bone;
				e.localpos=l;
			}
			static void initCOM(MotionUtil::Effector& e, vector3 const& l)
			{
				e.bone=NULL;
				e.localpos=l;
			}

			static void resize(std::vector<MotionUtil::Effector>& a, int size)
			{
				a.resize(size);
			}

			static MotionUtil::Effector& at(std::vector<MotionUtil::Effector>& a, int b)
			{
				return a[b];
			}
		};
		module(L, "MotionUtil")[
			def("retargetEntireMotion", &MotionUtil::retargetEntireMotion),
			def("exportVRML", &MotionUtil::exportVRML),
			def("exportVRMLforRobotSimulation", &MotionUtil::exportVRMLforRobotSimulation),
			def("createFullbodyIk_MultiTarget", &MotionUtil::createFullbodyIk_MultiTarget, luabind::adopt(luabind::result)),
			class_<std::vector<MotionUtil::Effector> >("Effectors")
			.def(constructor<>())
			.def("resize", &FIK_::resize)
			.def("at", &FIK_::at)
			.def("__call", &FIK_::at),
			class_<MotionUtil::Effector>("Effector")
			.def("init", &FIK_::init)
			.def("initCOM",&FIK_::initCOM)
			.def_readwrite("bone", &MotionUtil::Effector::bone)
			.def_readwrite("localpos", &MotionUtil::Effector::localpos),
			class_<MotionUtil::FullbodyIK>("FullbodyIK")
			.def("IKsolve", (void (MotionUtil::FullbodyIK::*)(Posture& , vector3N const& ))(&MotionUtil::FullbodyIK::IKsolve))
			.def("IKsolve", (void (MotionUtil::FullbodyIK::*)(Posture const&, Posture&, vector3N const& ))(&MotionUtil::FullbodyIK::IKsolve)),
			class_<MotionUtil::FullbodyIK_MotionDOF>("FullbodyIK_MotionDOF")
			.def("IKsolve", (void (MotionUtil::FullbodyIK_MotionDOF::*)(vectorn const& , vectorn& , vector3N const& ))&MotionUtil::FullbodyIK_MotionDOF::IKsolve)
			.def("IKsolve", (void (MotionUtil::FullbodyIK_MotionDOF::*)(vectorn& , vector3N const& ))&MotionUtil::FullbodyIK_MotionDOF::IKsolve)
			,def("createFullbodyIkDOF_MultiTarget", &MotionUtil::createFullbodyIk_MotionDOF_MultiTarget, luabind::adopt(luabind::result))
			,def("createFullbodyIkDOF_limbIK", &MotionUtil::createFullbodyIkDOF_limbIK, luabind::adopt(luabind::result))
			,def("createFullbodyIkDOF_limbIK_straight", &MotionUtil::createFullbodyIkDOF_limbIK_straight, luabind::adopt(luabind::result))
			,def("setLimbIKParam_straight", &MotionUtil::setLimbIKParam_straight)
			,class_<PoseTransfer>("PoseTransfer")
			.def(constructor<MotionLoader*, MotionLoader*, const char*,bool>())
			.def("setTargetSkeleton", &PoseTransfer::setTargetSkeleton)
			.def("setTargetSkeletonBothRotAndTrans", &PoseTransfer::setTargetSkeletonBothRotAndTrans)
			.def("source", &PoseTransfer::source)
			.def("target", &PoseTransfer::target)
		];
	}

	{
		struct ParseGrcFile_
		{
			static std::string class_(ParseGrcFile const& p, int isegment, const char* classifier)
			{
				int clsf=p.findClassifier(classifier);
				return std::string(p.className(clsf, p.classIndex(isegment, clsf)).ptr());
			}

			static std::string typeName(ParseGrcFile & p, int isegment){return std::string(p.typeName(isegment).ptr());}
			static int startTime(ParseGrcFile const& p, int iseg){return p.startTime(iseg);}
			static int endTime(ParseGrcFile const& p, int iseg){return p.endTime(iseg);}
		};
		module(L, "MotionUtil")[
			class_<ParseGrcFile>("ParseGrcFile")
				.def(constructor<>())
				.def(constructor<const char*>())
				.def("findSegment",  &ParseGrcFile::findSegment)
				.def("numClassifier",  &ParseGrcFile::numClassifier)
				.def("numClass",  &ParseGrcFile::numClass)
				.def("numSegment",  &ParseGrcFile::numSegment)
				.def("findClassifier",  &ParseGrcFile::findClassifier)
				.def("findClass",  &ParseGrcFile::findClass)
				.def("startTime",  &ParseGrcFile_::startTime)
				.def("endTime",  &ParseGrcFile_::endTime)
				.def("classIndex",  &ParseGrcFile::classIndex)
				.def("search", &ParseGrcFile::search)
				.def("class",  &ParseGrcFile_::class_)
				.def("typeName", &ParseGrcFile_::typeName)
		];
	}

	module(L)[
		class_<QuadraticFunction> ("QuadraticFunction")
		.def(constructor<>())
		.def("addSquared", 	(void (QuadraticFunction::*)(intvectorn const& , vectorn const& ))&QuadraticFunction::addSquared)
		.def("buildSystem", &QuadraticFunction::buildSystem)
		,
		class_<QuadraticFunctionHardCon> ("QuadraticFunctionHardCon")
			.def(constructor<int,int>())
			.def_readonly("numCon", &QuadraticFunctionHardCon::mNumCon)
			.def_readonly("numVar", &QuadraticFunctionHardCon::mNumVar)
			.def("addSquared", 	(void (QuadraticFunction::*)(intvectorn const& , vectorn const& ))&QuadraticFunction::addSquared)
			.def("addCon", (void (QuadraticFunctionHardCon::*)(intvectorn const&, vectorn const&))&QuadraticFunctionHardCon::addCon)
			.def("buildSystem", &QuadraticFunctionHardCon::buildSystem)
			];
  }


