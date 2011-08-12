
/*
   luabind로 바꾸는 중.
   lua
   function f(a) return a.x+a.y end

// C++
luabind::object table = luabind::newtable(L);
table["x"] = 1;
table["y"] = 2;
functor<int> f(L,"f");
f(table);

You can put a table into another table.

// C++
luabind::object table = luabind::newtable(L);
luabind::object subtable = luabind::newtable(L);
table["sub"] = subtable;
functor<int> f(L,"f");
f(table);

*/

#include "stdafx.h"
#include "BaselibLUA.h"
#include "../OgreFltk/MotionPanel.h"
#include "../BaseLib/image/Image.h"
#include "../BaseLib/image/ImageProcessor.h"
#include "../BaseLib/motion/MotionRetarget.h"
#include "../BaseLib/motion/Concat.h"
#include "../BaseLib/motion/MotionUtilSkeleton.h"
#include "../BaseLib/motion/MotionUtil.h"
#include "../BaseLib/motion/ConstraintMarking.h"
#include "../BaseLib/motion/postureip.h"
#include "../BaseLib/math/Operator.h"
#include "../BaseLib/math/GnuPlot.h"
#include "../BaseLib/math/conversion.h"
#include "../BaseLib/math/stransf.h"
#include "../BaseLib/math/Filter.h"
#include "../BaseLib/math/matrix3.h"
#include "../BaseLib/math/BSpline.h"
#include "../BaseLib/utility/operatorString.h"
#include "../BaseLib/utility/QPerformanceTimer.h"
#include "../BaseLib/utility/tfile.h"
#include "../BaseLib/math/GnuPlot.h"

#include "OR_LUA_Stack.h"


#ifdef _MSC_VER
#ifndef VC_EXTRALEAN
#define VC_EXTRALEAN		// Windows 헤더에서 거의 사용되지 않는 내용을 제외시킵니다.
#endif

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#endif

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

#include "BaselibLUA2.h"
#include "BaselibLUA3.h"

TString getCurrentDirectory();

namespace BaselibLUA {
	// String manipulation 함수들.
	int str_left(lua_State* L) // str_left("asdfasdf", 4)=="asdf", str_left("afffasdf",-3)=="afffa"
	{
		OR::LUAStack lua(L);
		TString in;
		int n;
		lua>>in>>n;
		lua<<in.left(n);
		return 1;
	}

	int str_right(lua_State* L) // str_right("asdfasdf", 4)=="asdf", str_right("asdfasdf",-2)=="dfasdf"
	{
		OR::LUAStack lua(L);
		TString in;
		int n;
		lua>>in>>n;
		lua<<in.right(n);
		return 1;
	}

	int str_include(lua_State* L)	// str_include("asdfasdff", "asdf")=true
	{
		OR::LUAStack lua(L);
		TString in, sub;
		lua>>in>>sub;
		if(in.findStr(0, sub)!=-1)
			lua.pushBoolean(true);
		else
			lua.pushBoolean(false);

		return 1;

	}

	int isFileExist(lua_State* L)
	{
		OR::LUAStack lua(L);
		TString fn;
		lua>>fn;
		if(::IsFileExist(fn))
			lua<<1;
		else
			lua<<0;
		return 1;
	}

#define method(name) {#name, &name}

	static luaL_reg PostProcessGlue[] =
	{
		method(str_left),
		method(str_right),
		method(str_include),
		method(isFileExist),
		{NULL, NULL}
	};

}

#include "../gsl_addon/optimizer.h"
#include "../BaseLib/math/cma/CMAwrap.h"


struct FuncWrapper: luabind::wrap_base, ObjectiveFunction
{
	FuncWrapper()
	{

	}

	virtual ~FuncWrapper()
	{
	}

	virtual vectorn& getInout() {
		return call<vectorn&>("getInout");
	}

	virtual double func(const vectorn& x)
	{
		return call<double>("func",boost::ref(x));
	}

	virtual double func_dfunc(const vectorn& x, vectorn& dx)
	{
		return call<double>("func_dfunc", boost::ref(x),boost::ref(dx));
	}

	virtual void info(int iter)
	{
		call<void>("info", iter);
	}
};




using namespace luabind;
void addBaselibModule(lua_State* L)
{
	for(int i=0; BaselibLUA ::PostProcessGlue[i].name; i++)
		lua_register(L, BaselibLUA ::PostProcessGlue[i].name, BaselibLUA ::PostProcessGlue[i].func);

	// assumes that L is already opened and that luabind::open(L) is already called.

	// image
	{
		module(L)[
			class_<CImage>("CImage")
			.def(constructor<>())
			.def("GetWidth", &CImage::GetWidth)
			.def("GetHeight", &CImage::GetHeight)
			.def("Load", &CImage::Load)
			.def("Save", &CImage::Save)
			.def("save", &CImage::save)
			.def("create", &CImage::Create)
			.def("CopyFrom", &CImage::CopyFrom)
			.def("concatVertical", &Imp::concatVertical)
			.def("rotateRight", &Imp::rotateRight)
			.def("rotateLeft", &Imp::rotateLeft)
			.def("sharpen", &Imp::sharpen)
			.def("contrast", &Imp::contrast)
			.def("dither", &Imp::dither)
			.def("gammaCorrect", &Imp::gammaCorrect)
			.def("gamma", &Imp::gammaCorrect)
			.def("crop", &Imp::crop)
			.def("resize", &Imp::resize)
			.def("blit", &Imp::blit)
			.def("drawBox", &Imp::drawBox),
			class_<TRect>("TRect")
				.def(constructor<>())
				.def(constructor<int,int,int,int>())
				.def_readwrite("left", &TRect::left)
				.def_readwrite("right", &TRect::right)
				.def_readwrite("top", &TRect::top)
				.def_readwrite("bottom", &TRect::bottom)

				];
	}


	// utility, string.
	{
		struct util_
		{
			static void sleep(int ms)
			{
#ifdef _MSC_VER
				::Sleep(ms);
#endif
			}
			static bool isFileExist(const char* fn)
			{
				return ::IsFileExist(fn);
			}

#ifdef _MSC_VER
			static unsigned int createProcess(const char* programpath, const char* commandline)
			{
				PROCESS_INFORMATION pi;
				STARTUPINFO si;	


				memset(&si,0,sizeof(si));
				si.cb= sizeof(si);

				TString pp(programpath);
				TString cd(commandline);

				if (!CreateProcess(&pp[0], &cd[0], NULL, NULL, false, 0, NULL,NULL,&si,&pi))
					throw std::runtime_error("programpath");

				return (unsigned int)pi.hProcess;
			}

			static void waitForSingleObject(unsigned int handle, int secondsToWait)
			{
				WaitForSingleObject((HANDLE)handle, (secondsToWait * 1000));
			}
#endif      
			static std::string getCurrentDirectory()
			{
				return std::string(::getCurrentDirectory().ptr());
			}

			static void msgBox(const char* msg)
			{
				Msg::msgBox("%s", msg);
			}

			static std::string unpackStr(BinaryFile& b)
			{
				TString ppp=b.unpackStr();
				if (ppp.length()==0)
					return std::string("");
				return std::string(ppp.ptr());	
			}
		};

		struct BinaryFile_
		{
			static void pack(BinaryFile& file, boolN const& b)
			{
				bitvectorn bb=b.bit();
				file.pack(bb);
			}

			static void unpack(BinaryFile& file, boolN & b)
			{
				bitvectorn bb;
				file.unpack(bb);
				b.assignBit(bb);
			}

			static void _unpackBit(BinaryFile& file, boolN & b)
			{
				bitvectorn bb;
				file._unpackBit(bb);
				b.assignBit(bb);
			}
			static std::string _unpackStr(BinaryFile& bf)
			{
				return std::string(bf._unpackStr().ptr());
			}

		};

		struct math_
		{
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

			static void drawSignals(const char* filename, matrixn & in)
			{
				intvectorn temp;
				m0::drawSignals a(filename,0,0,true, temp);
				a.calc(in);
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
		};

		module(L, "util")[
			def("sleep", &util_::sleep),
			def("isFileExist", &util_::isFileExist),
			def("getCurrentDirectory", &util_::getCurrentDirectory),
			def("msgBox", &util_::msgBox),
			def("outputToFile", &OutputToFile),
			def("_throwTest", &math_::_throwTest),
#ifdef _MSC_VER
			def("createProcess", &util_::createProcess),
			def("waitForSingleObject", &util_::waitForSingleObject),
#endif
			class_<QPerformanceTimerCount>("PerfTimer")
				.def(constructor<int, const char*>())
				.def("start", &QPerformanceTimerCount::start)
				.def("stop", &QPerformanceTimerCount::stop),
			class_<QPerformanceTimerCount2>("PerfTimer2")
				.def(constructor<>())
				.def("reset", &QPerformanceTimerCount2::reset)
				.def("start", &QPerformanceTimerCount2::start)
				.def("pause", &QPerformanceTimerCount2::pause)
				.def("stop", &QPerformanceTimerCount2::stop),


			class_<BinaryFile>("BinaryFile")
				.def(constructor<>())
				.def(constructor<bool>())
				.def(constructor<bool, const char*>())
				.def("openWrite", &BinaryFile::openWrite)
				.def("openRead", &BinaryFile:: openRead)
				.def("close", &BinaryFile::  close)
				.def("packInt", &BinaryFile::  packInt)
				.def("packFloat", &BinaryFile::  packFloat)
				.def("pack", &BinaryFile_::pack)
				.def("pack", (void (BinaryFile::*)(const char*))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const TString&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const vectorn&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const quater&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const vector3&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const intvectorn&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const matrixn&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const intmatrixn&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const vector3N&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const quaterN&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const TStrings&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const bitvectorn&))&BinaryFile::pack)
				.def("pack", (void (BinaryFile::*)(const matrix4&))&BinaryFile::pack)
				.def("unpackInt", (int (BinaryFile::*)())&BinaryFile::  unpackInt)
				.def("unpackFloat", (double (BinaryFile::*)())&BinaryFile::  unpackFloat)
				.def("unpackStr", &util_::unpackStr)
				.def("unpack", &BinaryFile_::unpack)
				.def("unpack", (void (BinaryFile::*)(TString&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(vectorn&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(quater&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(vector3&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(intvectorn&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(matrixn&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(intmatrixn&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(vector3N&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(quaterN&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(TStrings&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(bitvectorn&))&BinaryFile::unpack)
				.def("unpack", (void (BinaryFile::*)(matrix4&))&BinaryFile::unpack)
				.def("_unpackInt", (int (BinaryFile::*)())&BinaryFile::_unpackInt)
				.def("_unpackFloat", (double (BinaryFile::*)())&BinaryFile::_unpackFloat)
				.def("_unpackVec", &BinaryFile::_unpackVec)
				.def("_unpackMat", &BinaryFile::_unpackMat)
				.def("_unpackStr", &BinaryFile_::_unpackStr)
				.def("_unpackBit", &BinaryFile_::_unpackBit)
				.def("_unpack", &BinaryFile_::_unpackStr)
				.enum_("constants")
				[
				value("TYPE_INT", (int)BinaryFile::TYPE_INT),
			value("TYPE_FLOAT", (int)BinaryFile::TYPE_FLOAT),
			value("TYPE_FLOATN", (int)BinaryFile::TYPE_FLOATN),
			value("TYPE_INTN", (int)BinaryFile::TYPE_INTN),
			value("TYPE_BITN", (int)BinaryFile::TYPE_BITN),
			value("TYPE_FLOATMN", (int)BinaryFile::TYPE_FLOATMN),
			value("TYPE_INTMN", (int)BinaryFile::TYPE_INTMN),
			value("TYPE_BITMN", (int)BinaryFile::TYPE_BITMN),
			value("TYPE_STRING", (int)BinaryFile::TYPE_STRING),
			value("TYPE_STRINGN", (int)BinaryFile::TYPE_STRINGN),
			value("TYPE_ARRAY", (int)BinaryFile::TYPE_ARRAY) ,
			value("TYPE_EOF", (int)BinaryFile::TYPE_EOF)]

				];




		module(L , "math")
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


		module(L, "math")[
			def("gaussFilter", (void (*)(int kernelsize, matrixn& inout))&Filter::gaussFilter),
			def("gaussFilter", (void (*)(int kernelsize, vectorn& inout))&Filter::gaussFilter),
			def("calcKernelSize", &Filter::CalcKernelSize),
			class_<gnuPlotQueue>("gnuPlotQueue")
				.def(constructor<const char*, int, const char*>())
				.def(constructor<const char*, int, const char*, const char*, const char*>())
				.def(constructor<const char*, int, const char*, const char*, const char*, const char*>())
				.def("plotSignal", &gnuPlotQueue::plotSignal)
				.def("plotScattered",  &gnuPlotQueue::plotScattered)
				.def("plotParametric", &gnuPlotQueue::plotParametric),
			def("drawSignals", &math_::drawSignals),
			def("filter", &math_::filter),
			def("filterQuat", &math_::filterQuat),
			def("changeChartPrecision", &math_::changeChartPrecision),
			def("defaultPrecision", &math_::defaultPrecision),
			def("vecViewOffset",(vectornView (*)(vectorn const&,int)) &::vecViewOffset),
			def("vec3ViewOffset", &::vec3ViewOffset),
			def("quatViewOffset", &::quatViewOffset),
			def("PIsolve", &m::PIsolve),
			def("LUsolve", &m::LUsolve),
			def("alignAngles", &math_::alignAngles),
			class_<PointCloudMetric>("PointCloudMetric")
				.def(constructor<>())
				.def_readwrite("transfB", &PointCloudMetric::m_transfB)
				.def_readwrite("transformedB", &PointCloudMetric::m_transformedB)
				.def("calcDistance", &PointCloudMetric::CalcDistance),
			class_<WeightedPointCloudMetric>("WeightedPointCloudMetric")
				.def(constructor<vectorn const&>())
				.def_readwrite("errorOccurred", &WeightedPointCloudMetric::errorOccurred)
				.def_readwrite("transfB", &WeightedPointCloudMetric::m_transfB)
				.def_readwrite("transformedB", &WeightedPointCloudMetric::m_transformedB)
				.def("calcDistance", &WeightedPointCloudMetric::CalcDistance),
			class_<KovarMetric>("KovarMetric")
				.def(constructor<>())
				.def(constructor<bool>())
				.def_readwrite("transfB", &KovarMetric::m_transfB)
				.def_readwrite("transformedB", &KovarMetric::m_transformedB)
				.def("calcDistance", &KovarMetric::CalcDistance),

			class_<NonuniformSpline>("NonuniformSpline")
				.def(constructor<vectorn const&, const matrixn&>())
				.def("getCurve", &NonuniformSpline::getCurve)
				.def("getFirstDeriv", &NonuniformSpline::getFirstDeriv)
				.def("getSecondDeriv", &NonuniformSpline::getSecondDeriv)
				];

		struct sz1_
		{
			static std::string left(const char* a, int l)
			{
				return std::string (TString(a).left(l).ptr());
			}
			static std::string right(const char* a, int l)
			{
				return std::string (TString(a).right(l).ptr());
			}
			static std::string filename(const char* fn)
			{
				TString _fn_out, _dir;
				_fn_out=sz1::filename(fn, _dir);
				return std::string(_fn_out.ptr());
			}
			static std::string directory(const char* fn)
			{
				TString _fn_out, _dir;
				_fn_out=sz1::filename(fn, _dir);
				return std::string(_dir.ptr());
			}
			static std::string replace(const char* str, const char* pt1, const char* pt2)
			{
				TString temp(str);
				sz0::replace(pt1,pt2)(temp);
				return std::string(temp.ptr());
			}

			static std::string parentDirectory(const char* child)
			{
				TString childDirectory(child);
				for(int i=1,ni=childDirectory.length(); i<ni; i++)
				{
					if(childDirectory[ni-i-1]=='\\')
					{
						return std::string(childDirectory.left(-1*i).ptr());
					}
				}
				return std::string("(NULL)");
			}

			static int length(const char* f)
			{
				return strlen(f);
			}
		};

		module(L, "str")[
			def("left", &sz1_::left),
			def("right", &sz1_::right),
			def("filename", &sz1_::filename),
			def("directory", &sz1_::directory),
			def("replace", &sz1_::replace),
			def("parentDirectory", &sz1_::parentDirectory),
			def("length", &sz1_::length)
				];
	}
	// vector3
	{
		void (vector3::*add1)(const vector3&, const vector3&) =&vector3::add;
		void (vector3::*sub1)(const vector3&, const vector3&) =&vector3::sub;
		void (vector3::*cross1)(const vector3&, const vector3&) =&vector3::cross;
		void (vector3::*add2)(const vector3&) =&vector3::add;
		void (vector3::*sub2)(const vector3&) =&vector3::sub;

		struct vector3_wrap
		{
			static void assign(vector3& l, object const& ll)
			{
				if (type(ll) != LUA_TTABLE)
					throw std::range_error("vector3_assign");
				l.x=object_cast<double>(ll[1]);	// lua indexing starts from 1.
				l.y=object_cast<double>(ll[2]);
				l.z=object_cast<double>(ll[3]);
			}
			static void assign2(vector3& l, vector3 const& ll)
			{
				l=ll;
			}
			static std::string out(vector3& v)
			{
				return std::string(v.output());
			}
			static vector3 __mul(vector3 const& a, m_real b)
			{vector3 c;c.mult(a,b);return c;}
			static vector3 __mul2(m_real b, vector3 const& a)
			{vector3 c;c.mult(a,b);return c;}



			static vector3 __div(vector3 const& a, m_real b)
			{
				vector3 c;
				c.mult(a,1.0/b);
				return c;
			}

			static vector3 __add(vector3 const& a, vector3 const& b)
			{vector3 c;c.add(a,b);return c;}

			static vector3 __sub(vector3 const& a, vector3 const& b)
			{vector3 c;c.sub(a,b);return c;}
			static double dotProduct(vector3 const& a, vector3 const& b)
			{
				return a%b;
			}

		};

		module(L)[
			class_<vector3>("vector3")
			.def(constructor<>())
			.def(constructor<m_real>())
			.def(constructor<m_real, m_real, m_real>())
			.def_readwrite("x", &vector3::x)
			.def_readwrite("y", &vector3::y)
			.def_readwrite("z", &vector3::z)
			.def("add", add1)
			.def("sub", sub1)
			.def("__add", &vector3_wrap::__add)
			.def("__sub", &vector3_wrap::__sub)
			.def("__div", &vector3_wrap::__div)
			.def("__mul", &vector3_wrap::__mul)
			.def("__mul", &vector3_wrap::__mul2)
			.def("radd", add2)
			.def("rsub", sub2)
			.def("zero", &vector3::zero)
			.def("scale", (void (vector3::*)(m_real))&vector3::operator*=)
			.def("cross", cross1)
			.def("cross", (vector3 (vector3::*)(const vector3& other) const)&vector3::cross)
			.def("distance", &vector3::distance)
			.def("normalize", (void (vector3::*)())&vector3::normalize)
			.def("multadd", &vector3::multadd)
			.def("length", &vector3::length)
			.def("dotProduct", &vector3_wrap::dotProduct)
			.def("angularVelocity", &vector3::angularVelocity)
			.def(-self) // neg (unary minus)
			.def(self + self) // add (homogeneous)
			.def(self * self) // mul
			.def("assign", &vector3_wrap::assign)
			.def("assign", &vector3_wrap::assign2)
			.def("set", &vector3_wrap::assign)
			.def("setValue", (void   (vector3::*)(m_real xx, m_real yy, m_real zz )	)&vector3::setValue)
			.def("interpolate", &vector3::interpolate)
			.def("difference", &vector3::difference)
			.def("rotate", (void (vector3::*)( const quater& q, vector3 const& in))&vector3::rotate)
			.def("rotate", (void (vector3::*)( const quater& q))&vector3::rotate)
			.def("rotationVector", &vector3::rotationVector)
			.def("__tostring", &vector3_wrap::out)
			];
	}


	// TStrings
	{

		struct TStrings_wrap
		{
			static void assign(TStrings& l, object const& ll)
			{
				if (type(ll) != LUA_TTABLE)
					throw std::range_error("TStrings_assign");

				l.resize(0);

				for(luabind::iterator i(ll), end; i!=end; ++i)
				{
					l.pushBack(luabind::object_cast<const char*>(*i));
				}
			}
			static std::string out(TStrings& v, int i)
			{
				if( v[i].length()==0) 
					return std::string(" ");

				return std::string(v[i]);
			}
			static int length(TStrings& v, int i)
			{
				return v[i].length();
			}

			static void in(TStrings& v, int i, const char* a)
			{
				v[i]=a;
			}

		};

		struct TString_
		{
			static std::string __tostring(TString const& in) {  if (in.ptr()) return std::string(in.ptr()); return std::string("");}
			static void assign(TString & out, std::string const& in) { out=in.c_str();}
		};

		module(L)[
			class_<TStrings>("TStrings")
			.def(constructor<>())
			.def("assign", &TStrings_wrap::assign)
			.def("data", &TStrings_wrap::out)
			.def("__call", &TStrings_wrap::out)
			.def("length", &TStrings_wrap::length)
			.def("setData", &TStrings_wrap::in)
			.def("set", &TStrings_wrap::in)
			.def("resize", &TStrings::resize)
			.def("size", &TStrings::size)
			.def("find", &TStrings::find),
			class_<TString>("TString")
				.def(constructor<>())
				.def("__tostring", &TString_::__tostring)
				.def("length", &TString::length)
				.def("assign", &TString_::assign)

				];

	}

	// quater
	{
		struct quater_wrap
		{
			static void decompose(quater const& l, quater &a, quater& b)
			{
				l.decomposeTwistTimesNoTwist(vector3(0,1,0), a, b);
			}
			static void assign(quater& l, object const& ll)
			{
				if (type(ll) != LUA_TTABLE)
					throw std::range_error("quater_assign");
				l.w=object_cast<double>(ll[1]);	// lua indexing starts from 1.
				l.x=object_cast<double>(ll[2]);	// lua indexing starts from 1.
				l.y=object_cast<double>(ll[3]);
				l.z=object_cast<double>(ll[4]);
			}
			static void assign2(quater& l, quater const& ll)
			{
				l=ll;
			}
			static std::string out(quater& v)
			{
				return std::string(v.output());
			}

			static m_real toRadian(m_real deg)
			{
				return TO_RADIAN(deg);
			}

			static m_real toDegree(m_real rad)
			{
				return TO_DEGREE(rad);
			}

			static void setRotation(quater &q, const char* aChannel, vector3 & euler)
			{
				q.setRotation(aChannel, euler);
			}

			static void getRotation(quater const&q, const char* aChannel, vector3 & euler)
			{
				q.getRotation(aChannel, euler);
			}
			static vector3 getRotation2(quater const&q, const char* aChannel)
			{
				vector3 euler;
				q.getRotation(aChannel, euler);
				return euler;
			}

			static vector3 rotate(quater const& q, vector3 const& v)
			{
				vector3 out;
				out.rotate(q,v);
				return out;
			}

		};


		m_real (quater::*rotationAngle1)(void) const=&quater::rotationAngle;
		void (quater::*normalize1)()=&quater::normalize;

		module(L)[
			def("toRadian",&quater_wrap::toRadian),
			def("toDegree",&quater_wrap::toDegree),
			class_<quater>("quater")
				.def(constructor<>())
				.def(constructor<m_real, m_real, m_real, m_real>())
				.def(constructor<m_real , const vector3& >())
				.def_readwrite("x", &quater::x)
				.def_readwrite("y", &quater::y)
				.def_readwrite("z", &quater::z)
				.def_readwrite("w", &quater::w)
				.def("slerp", &quater::slerp)
				.def("safeSlerp", &quater::safeSlerp)
				.def("interpolate", &quater::interpolate)
				.def("setAxisRotation", &quater::setAxisRotation)
				.def("identity", &quater::identity)
				.def("inverse", (quater (quater::*)(void)const)&quater::inverse)
				.def("decompose", &quater_wrap::decompose)
				.def("decomposeTwistTimesNoTwist", &quater::decomposeTwistTimesNoTwist)
				.def("decomposeNoTwistTimesTwist", &quater::decomposeNoTwistTimesTwist)
				.def("difference", &quater::difference)
				.def("scale", &quater::scale)
				.def("mult", (void (quater::*)(quater const& a, quater const& b)) &quater::mult)
				.def(-self) // neg (unary minus)
				.def(self + self) // add (homogeneous)
				.def(self * self) // mul
				.def("length", &quater::length)
				.def("rotationAngle", rotationAngle1)
				.def("rotate", &quater_wrap::rotate)
				.def("rotationAngleAboutAxis", &quater::rotationAngleAboutAxis)
				.def("rotationVector", &quater::rotationVector)
				.def("assign", &quater_wrap::assign)
				.def("assign", &quater_wrap::assign2)
				.def("set", &quater_wrap::assign)
				.def("setValue", (void (quater::*)( m_real ww,m_real xx, m_real yy, m_real zz ))(&quater::setValue))
				.def("axisToAxis", &quater::axisToAxis)
				.def("leftMult", &quater::leftMult)
				.def("rightMult", &quater::rightMult)
				.def("setRotation", (void (quater::*)(const vector3&, m_real))&quater::setRotation)
				.def("setRotation", (void (quater::*)(const vector3& ))&quater::setRotation)
				.def("setRotation", (void (quater::*)(const matrix4& a))&quater::setRotation)
				.def("setRotation", &quater_wrap::setRotation)
				.def("getRotation", &quater_wrap::getRotation)
				.def("getRotation", &quater_wrap::getRotation2)
				.def("normalize", normalize1)
				.def("align", &quater::align)
				.def("__tostring", &quater_wrap::out)
				.def(const_self*other<vector3 const&>())
				];
	}

	// matrix4
	{
		struct wrap_matrix4
		{
			static void assign2(matrix4& l, matrix4 const& m)
			{
				l=m;
			}
			static void assign(matrix4& l, object const& ll)
			{
				if(LUAwrapper::arraySize(ll)!=16) throw std::range_error("matrix4_assign");
				l._11=object_cast<double>(ll[1]);
				l._12=object_cast<double>(ll[2]);
				l._13=object_cast<double>(ll[3]);
				l._14=object_cast<double>(ll[4]);
				l._21=object_cast<double>(ll[5]);
				l._22=object_cast<double>(ll[6]);
				l._23=object_cast<double>(ll[7]);
				l._24=object_cast<double>(ll[8]);
				l._31=object_cast<double>(ll[9]);
				l._32=object_cast<double>(ll[10]);
				l._33=object_cast<double>(ll[11]);
				l._34=object_cast<double>(ll[12]);
				l._41=object_cast<double>(ll[13]);
				l._42=object_cast<double>(ll[14]);
				l._43=object_cast<double>(ll[15]);
				l._44=object_cast<double>(ll[16]);
			}
			static std::string out(matrix4& l)
			{
				TString v;
				v.format(" %f %f %f %f\n %f %f %f %f\n %f %f %f %f\n %f %f %f %f\n", l._11,l._12,l._13,l._14,l._21,l._22,l._23,l._24,l._31,l._32,l._33,l._34,l._41,l._42,l._43,l._44);
				return std::string(v.ptr());
			}
			static void setRotation(matrix4& l, quater const& q)
			{
				l.setRotation(q);
			}

			static matrix4 inverse(matrix4 const& m)
			{
				matrix4 t;
				t.inverse(m);
				return t;
			}
		};
		struct wrap_matrix3
		{
#ifndef _MSC_VER
			static vector3  __mul_mv(matrix3 const& a, vector3 const& b)
			{
				return a*b;
			}

			static vector3 __mul_vm(vector3 const& b, matrix3 const& a)
			{
				return b*a;
			}

			static matrix3 __mul_mm(matrix3 const& a, matrix3 const& b)
			{
				return a*b;
			}
#endif

			static void assign(matrix3& l, object const& ll)
			{
				if(LUAwrapper::arraySize(ll)!=9) throw std::range_error("matrix4_assign");
				l._11=object_cast<double>(ll[1]);
				l._12=object_cast<double>(ll[2]);
				l._13=object_cast<double>(ll[3]);
				l._21=object_cast<double>(ll[4]);
				l._22=object_cast<double>(ll[5]);
				l._23=object_cast<double>(ll[6]);
				l._31=object_cast<double>(ll[7]);
				l._32=object_cast<double>(ll[8]);
				l._33=object_cast<double>(ll[9]);
			}
			static std::string out(matrix3& l)
			{
				TString v;
				v.format(" %f %f %f\n %f %f %f\n %f %f %f\n", l._11,l._12,l._13,l._21,l._22,l._23,l._31,l._32,l._33);
				return std::string(v.ptr());
			}
		};

		module(L)[
			class_<matrix4>("matrix4")
			.def_readwrite("_11", &matrix4::_11)
			.def_readwrite("_12", &matrix4::_12)
			.def_readwrite("_13", &matrix4::_13)
			.def_readwrite("_14", &matrix4::_14)
			.def_readwrite("_21", &matrix4::_21)
			.def_readwrite("_22", &matrix4::_22)
			.def_readwrite("_23", &matrix4::_23)
			.def_readwrite("_24", &matrix4::_24)
			.def_readwrite("_31", &matrix4::_31)
			.def_readwrite("_32", &matrix4::_32)
			.def_readwrite("_33", &matrix4::_33)
			.def_readwrite("_34", &matrix4::_34)
			.def_readwrite("_41", &matrix4::_41)
			.def_readwrite("_42", &matrix4::_42)
			.def_readwrite("_43", &matrix4::_43)
			.def_readwrite("_44", &matrix4::_44)
			.def(constructor<>())
			.def(constructor<const quater&, const vector3&>())
			.def(constructor<const transf&>())
			.def("assign", &wrap_matrix4::assign)
			.def("assign", &wrap_matrix4::assign2)
			.def("identity", &matrix4::identity)
			.def("__tostring", &wrap_matrix4::out)
			.def("setRotation", &wrap_matrix4::setRotation)
			.def("setRotation", (void (matrix4::*)(const vector3& axis, m_real angle, bool bPreserveCurrentTranslation) )&matrix4::setRotation)
			.def("setScaling", &matrix4::setScaling)
			.def("leftMultRotation", (void (matrix4::*)(const vector3& axis, m_real angle) )&matrix4::leftMultRotation)
			.def("leftMultRotation", (void (matrix4::*)(const quater& q) )&matrix4::leftMultRotation)
			.def("leftMultTranslation", &matrix4::leftMultTranslation)
			.def("leftMultScaling", &matrix4::leftMultScaling)
			.def("leftMult", (void (matrix4::*)(const matrix4&))&matrix4::leftMult)
			.def("rightMult",(void (matrix4::*)(const matrix4&)) &matrix4::rightMult)
			.def("inverse", &matrix4::inverse)
			.def("inverse", &wrap_matrix4::inverse)
			.def(const_self*other<vector3 const&>())
			.def(const_self*other<matrix4 const&>())
			.def(const_self-other<matrix4 const&>())
			.def(const_self+other<matrix4 const&>()),
			class_<matrix3>("matrix3")
				.def_readwrite("_11", &matrix3::_11)
				.def_readwrite("_12", &matrix3::_12)
				.def_readwrite("_13", &matrix3::_13)
				.def_readwrite("_21", &matrix3::_21)
				.def_readwrite("_22", &matrix3::_22)
				.def_readwrite("_23", &matrix3::_23)
				.def_readwrite("_31", &matrix3::_31)
				.def_readwrite("_32", &matrix3::_32)
				.def_readwrite("_33", &matrix3::_33)
				.def(constructor<>())
				.def(constructor<matrix3 const&>())
				.def("assign", &wrap_matrix3::assign)
				.def("setValue", (void (matrix3::*)(m_real, m_real, m_real, m_real, m_real, m_real, m_real, m_real, m_real))&matrix3::setValue)
				.def("identity", &matrix3::identity)
				.def("zero", &matrix3::zero)
				.def("inverse", (bool (matrix3::*)(matrix3 const&))&matrix3::inverse)
				.def("transpose", &matrix3::transpose)
				.def("setTilde", (void (matrix3::*)( vector3 const &v ))&matrix3::setTilde)
				.def("__tostring", &wrap_matrix3::out)
				.def("setFromQuaternion", &matrix3::setFromQuaternion)
				.def("mult", (void (matrix3::*)(matrix3 const& a,matrix3 const& b))&matrix3::mult)
				.def("mult", (void (matrix3::*)(matrix3 const& a,m_real b))&matrix3::mult)

#ifdef _MSC_VER
				.def("__mul", (vector3 (*)(matrix3 const& a, vector3 const& b))&operator*)
				.def("__mul", (vector3 (*)(vector3 const& b, matrix3 const& a))&operator*)
				.def("__mul", (matrix3 (*)(matrix3 const& a, matrix3 const& b))&operator*)
#else
				.def("__mul", &wrap_matrix3::__mul_mv)
				.def("__mul", &wrap_matrix3::__mul_vm)
				.def("__mul", &wrap_matrix3::__mul_mm)
#endif
				];

		struct transf_
		{
			static void assign(transf &b, transf const& a)
			{
				b.rotation=a.rotation;
				b.translation=a.translation;
			}

			static vector3 mul_tv(transf const& a, vector3 const& b)
			{
				return a*b;
			}
			static transf mul_tt(transf const& a, transf const& b)
			{
				return a*b;
			}



		};
		module(L)[
			class_<transf>("transf")
			.def(constructor<>())
			.def(constructor<quater const&, vector3 const&>())
			.def(constructor<matrix4 const&>())

			.def_readwrite("rotation", &transf::rotation)
			.def_readwrite("translation",&transf::translation)
			.def("toLocal",&transf::toLocal)
#ifdef _MSC_VER
			.def("__mul", (vector3 (*)(transf const&, vector3 const&))&operator*)
			.def("__mul", (transf (*)(transf const&, transf const&))&operator*)		
#else
			.def("__mul", &transf_::mul_tv)
			.def("__mul", &transf_::mul_tt)
#endif
			.def("toGlobal",&transf::toGlobal)
			.def("inverse", &transf::inverse)
			.def("difference", &transf::difference)
			.def("toLocalRot",&transf::toLocalRot)
			.def("toGlobalRot",&transf::toGlobalRot)
			.def("toLocalDRot",&transf::toLocalDRot)
			.def("toGlobalDRot",&transf::toGlobalDRot)
			.def("toLocalPos",&transf::toLocalPos)
			.def("toGlobalPos",&transf::toGlobalPos)
			.def("toLocalDir",&transf::toLocalDir)
			.def("toGlobalDir",&transf::toGlobalDir)
			.def("assign", &transf_::assign)
			.def("encode2D", &transf::encode2D)
			.def("decode2D", &transf::decode2D)
			];

		struct stransf_
		{
			static void assign(stransf &b, stransf const& a)
			{
				b=a;
			}

			static stransf mul_ss(stransf const& a, stransf const&b) {return a*b;}
			static vector3 mul_sv(stransf const& a, vector3 const&b) {return a*b;}
		};

		module(L)[
			class_<stransf>("stransf")
			.def(constructor<>())
			.def(constructor<m_real, quater const&, vector3 const&>())
			.def_readwrite("scale", &stransf::scale)
			.def_readwrite("rotation", &stransf::rotation)
			.def_readwrite("translation",&stransf::translation)
			.def("toLocal",&stransf::toLocal)
			.def("toGlobal",&stransf::toGlobal)
			.def("toLocalRot",&stransf::toLocalRot)
			.def("toGlobalRot",&stransf::toGlobalRot)
			.def("assign", &stransf_::assign)
			.def("inverse", &stransf::inverse)
			.def("identity", &stransf::identity)
			.def("setCoordinate", &stransf::setCoordinate)
#ifdef _MSC_VER
			.def("__mul", (stransf (*)(stransf const&, stransf const&) )&operator*)
			.def("__mul", (vector3 (*)(stransf const&, vector3 const&) )&operator*)
#else
			.def("__mul", &stransf_::mul_ss)
			.def("__mul", &stransf_::mul_sv)
#endif
			];

	}
	{
		module(L)[
			class_<MotionUtil::FootstepDetection>("FootstepDetection")
			.def(constructor<Motion*, bool, bool, int, int>())
			.def("calcConstraint", &MotionUtil::FootstepDetection::calcConstraint)
			.enum_("constants")
			[
			value("CONSTRAINT_LEFT_FOOT",(int)CONSTRAINT_LEFT_FOOT),
			value("CONSTRAINT_RIGHT_FOOT",(int)CONSTRAINT_RIGHT_FOOT),
			value("CONSTRAINT_LEFT_HAND",(int)CONSTRAINT_LEFT_HAND),
			value("CONSTRAINT_RIGHT_HAND",(int)CONSTRAINT_RIGHT_HAND),
			value("CONSTRAINT_LEFT_TOE",(int)CONSTRAINT_LEFT_TOE),
			value("CONSTRAINT_LEFT_HEEL",(int)CONSTRAINT_LEFT_HEEL),
			value("CONSTRAINT_RIGHT_TOE",(int)CONSTRAINT_RIGHT_TOE),
			value("CONSTRAINT_RIGHT_HEEL",(int)CONSTRAINT_RIGHT_HEEL),
			value("CONSTRAINT_INTERACTION",(int)CONSTRAINT_INTERACTION),
			value("CONSTRAINT_CRI_INTERACTION",(int)CONSTRAINT_CRI_INTERACTION),
			value("WHICH_FOOT_IS_SUPPORTED",(int)WHICH_FOOT_IS_SUPPORTED),
			value("IS_FOOT_SUPPORTED",(int)IS_FOOT_SUPPORTED),
			value("POSE_IS_INVALID",(int)POSE_IS_INVALID),
			value("CONSTRAINT_LEFT_FINGERTIP",(int)CONSTRAINT_LEFT_FINGERTIP),
			value("CONSTRAINT_RIGHT_FINGERTIP",(int)CONSTRAINT_RIGHT_FINGERTIP),
			value("IS_DISCONTINUOUS",(int)IS_DISCONTINUOUS)
				]
				];
	}


	addBaselibModule2(L);



}

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
	//#include "luadebug.h"
}


int lua_dostring(lua_State* L, const char* str)
{
	return luaL_dostring(L,str);
}
int lua_dofile(lua_State* L, const char* str)
{
	return luaL_dofile(L,str);
}


void testLuaBind()
{
	try
	{
		LUAwrapper l;

		lua_dostring(l.L, "function add(first, second)\nprint(first,second)\nreturn 1\nend\n");

		int a=3;
		l.setVal<int>("a", a);
		vectorn b(4, 1.0, 2.0,3.0,4.0);
		l.setVal<vectorn>("b", b);
		b[2]=5;

		l.setRef<vectorn>("b_ref", b);

//
		//struct test_raw
		//{
			//static void greet(lua_State* L)
			//{
				//lua_pushstring(L, "hello");
			//}
		//};
//
		//module(l.L)
			//[
			//def("greet", &test_raw::greet, raw(_1))
			//];
//
		lua_dostring(l.L, "d=3");

		lua_dostring(l.L, "e=vectorn()\ne:assign({1,1,1,1})");

		lua_dostring(l.L, "e[0]=3\ne[1]=e[1]+1\n");


		int d;
		l.getVal<int>("d", d);
		cout << d;

		vectorn e;
		l.getVal<vectorn>("e", e);

		cout<<e.output().ptr();

#ifdef _MSC_VER
		vectorn& er=l.getRef<vectorn>("e");
		cout<<er.output().ptr();

		er[1]=3;
#endif
		cout << "Result: "
			<< luabind::call_function<int>(l.L, "add", "asdf", "3333");


		lua_dostring(l.L, "debug.debug()");
	}
	catch(luabind::error& e)
	{

		printf("lua error %s\n", e.what());
	}
}


