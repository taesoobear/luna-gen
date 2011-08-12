
#include "stdafx.h"
#include "BaselibLUA.h"
#include "../OgreFltk/MotionPanel.h"
#include "../BaseLib/motion/MotionRetarget.h"
#include "../BaseLib/motion/Concat.h"
#include "../BaseLib/motion/MotionUtilSkeleton.h"
#include "../BaseLib/motion/MotionUtil.h"
#include "../BaseLib/math/Operator.h"
#include "../BaseLib/math/OperatorStitch.h"
#include "../BaseLib/math/GnuPlot.h"
#include "../MainLib/OgreFltk/FlLayout.h"
#include "../MainLib/OgreFltk/Mesh.h"
#include "../MainLib/OgreFltk/objectList.h"
#include "../MainLib/Ogre/intersectionTest.h"

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
#include <luabind/class_info.hpp> 

struct RendererEventHandler: FltkRenderer ::Handler, luabind::wrap_base
{
	RendererEventHandler() { RE::FltkRenderer().setHandler(this);}

	virtual int handleRendererEvent(int ev)
	{
#ifndef NO_GUI
		if(ev==FL_PUSH || ev==FL_MOVE || ev==FL_DRAG || ev==FL_RELEASE)
			{
				int x=Fl::event_x();
				int y=Fl::event_y();
				int button=Fl::event_button();
				bool bButton1=Fl::event_state()&FL_BUTTON1;
				bool bButton2=Fl::event_state()&FL_BUTTON2;
				bool bButton3=Fl::event_state()&FL_BUTTON3;

				return call<int>("handleRendererEvent", ev, x,y, button, bButton1, bButton2, bButton3);
			}
#endif
		return 0;
	}
};


#ifndef NO_GUI

#include <FL/fl_ask.H>
#include <FL/Fl_Browser.H>
#endif
#ifndef NO_OGRE
#include <Ogre.h>

#define OGRE_VOID(x) x
#define OGRE_PTR(x) x
#else
#define OGRE_VOID(x)
#define OGRE_PTR(x) return NULL
#endif
//#include <OgreViewport.h>
//#include <OgreSceneNode.h>
//#include <OgreSceneManager.h>
//#include <OgreEntity.h>
//#include <OgreOverlayManager.h>
//
void RE_outputRaw(const char* key, const char* output, int i);
void RE_dumpOutput(TStrings& output, int i);
void RE_outputEraseAll(int i);
void FastCapture_convert(const char* filename){}


#ifdef NO_GUI
struct EventReceiver_wrapper: FrameMoveObject, luabind::wrap_base
{
	EventReceiver_wrapper()
	{
		RE::renderer().addFrameMoveObject(this);
	}

	virtual ~EventReceiver_wrapper()
	{
		RE::renderer().removeFrameMoveObject(this);
	}

	virtual int FrameMove(float fElapsedTime)   {call<void>("frameMove", fElapsedTime); return 1;}
	static void default_fm(EventReceiver_wrapper* ptr, float f)	
	{
	}
};
#else
struct EventReceiver_wrapper: FltkMotionWindow ::EventReceiver, FrameMoveObject, luabind::wrap_base
{
	EventReceiver_wrapper()
		: FltkMotionWindow ::EventReceiver()
	{
		RE::motionPanel().motionWin()->connect(*this);
		RE::renderer().addFrameMoveObject(this);
	}

	virtual ~EventReceiver_wrapper()
	{
		RE::motionPanel().motionWin()->disconnect(*this);
		RE::renderer().removeFrameMoveObject(this);
	}

	virtual void OnNext(FltkMotionWindow* win)	{call<void>("onNext", win);	}
	virtual void OnPrev(FltkMotionWindow* win)	{call<void>("onPrev", win);	}
	virtual void OnFrameChanged(FltkMotionWindow* win, int i)	{call<void>("onFrameChanged", win, i);	}

	virtual int FrameMove(float fElapsedTime)   {call<void>("frameMove", fElapsedTime); return 1;}
	static void default_on(FltkMotionWindow ::EventReceiver* ptr, FltkMotionWindow* win)
	{ptr->FltkMotionWindow ::EventReceiver::OnNext(win);	}
	static void default_op(FltkMotionWindow ::EventReceiver* ptr, FltkMotionWindow* win)
	{ptr->FltkMotionWindow ::EventReceiver::OnPrev(win);	}
	static void default_ofc(FltkMotionWindow ::EventReceiver* ptr, FltkMotionWindow* win, int i)	
	{ptr->FltkMotionWindow ::EventReceiver::OnFrameChanged(win, i);	}
	static void default_fm(FltkMotionWindow ::EventReceiver* ptr, float f)	
	{
	}
};
struct SelectUI_wrapper: FltkScrollPanel::SelectUI, luabind::wrap_base
{
	SelectUI_wrapper()
		: FltkScrollPanel::SelectUI()
	{
		RE::motionPanel().scrollPanel()->connectSelectUI(*this);
	}

	virtual ~SelectUI_wrapper()
	{
		RE::motionPanel().scrollPanel()->disconnectSelectUI(*this);
	}

	virtual void click(int iframe)	{call<void>("click", iframe);	}
	virtual void selected(int iframe, int endframe)	{call<void>("selected", iframe, endframe);	}
	virtual void panelSelected(const char* label, int iframe)	{call<void>("panelSelected", label, iframe);	}

	static void default_c(FltkScrollPanel::SelectUI* ptr, int iframe){}
	static void default_s(FltkScrollPanel::SelectUI* ptr, int iframe, int endframe){}
	static void default_ps(FltkScrollPanel::SelectUI* ptr, const char* label, int iframe){}
};
#endif
int FlGenShortcut(const char* s)
{
#ifdef NO_GUI
	return 0;
#else
	TString ss(s);

	TString token;
	int shortc=0;
	for(int start=0, end=ss.length(); start!=end; )
		{
			ss.token(start, "+", token) ;

			if(token=="FL_ALT")
				shortc+=FL_ALT;
			else if(token=="FL_CTRL")
				shortc+=FL_CTRL;
			else
				shortc+=token[0];
		}
	return shortc;
#endif
}
using namespace luabind;


#ifndef NO_OGRE
#define BEGIN_OGRE_CHECK try {
#define END_OGRE_CHECK	} catch ( Ogre::Exception& e ) {Msg::msgBox(e.getFullDescription().c_str());}

#include "OgreOverlayContainer.h"
#include "OgreOverlayElement.h"

namespace Ogre
{

	Ogre::OverlayContainer* createContainer(int x, int y, int w, int h, const char* name) ;
	Ogre::OverlayElement* createTextArea(const String& name, Real width, Real height, Real top, Real left, uint fontSize, const String& caption, bool show) ;
}

Ogre::Overlay* createOverlay_(const char* name)
{
	return Ogre::OverlayManager::getSingleton().create(name);
}

void destroyOverlay_(const char* name)
{
	Ogre::OverlayManager::getSingleton().destroy(name);
}
void destroyOverlayElement_(const char* name)
{
	Ogre::OverlayManager::getSingleton().destroyOverlayElement(name);
}
void destroyAllOverlayElements_()
{
	Ogre::OverlayManager::getSingleton().destroyAllOverlayElements();
}
Ogre::OverlayElement* createTextArea_(const char* name, double width, double height, double top, double left, int fontSize, const char* caption, bool show)
{
	return Ogre::createTextArea(name, width, height, top, left, fontSize, caption, show);
}

void addOverlay(lua_State* L)
{
	struct Overlay_
	{
		static void setCaption(Ogre::OverlayElement* p, const char* caption)
		{
			p->setCaption(caption);
		}

		static void setMaterialName(Ogre::OverlayElement* p, const char* c)
		{
			p->setMaterialName(c);
		}

		static void setParameter(Ogre::OverlayElement* p, const char* c, const char* d)
		{
			p->setParameter(c,d);
		}
	};
	module(L, "Ogre")[
					  def("createContainer", &Ogre::createContainer),
					  def("createTextArea", &createTextArea_),
					  def("createOverlay", &createOverlay_),
					  def("destroyOverlay", &destroyOverlay_),
					  def("destroyOverlayElement",&destroyOverlayElement_),
					  def("destroyAllOverlayElements", &destroyAllOverlayElements_),
					  class_<Ogre::Overlay>("OverlayContainer")
					  .def("setZOrder", &Ogre::Overlay::setZOrder)
					  .def("add2D", &Ogre::Overlay::add2D)
					  .def("show", &Ogre::Overlay::show)
					  .def("hide", &Ogre::Overlay::hide)
					  ,class_<Ogre::OverlayElement>("OverlayElement")
					  .def("setCaption",&Overlay_::setCaption)
					  .def("setMaterialName", &Overlay_::setMaterialName)
					  .def("setParameter", &Overlay_::setParameter)
					  ,class_<Ogre::OverlayContainer,Ogre::OverlayElement>("OverlayContainer")
					  .def("addChild", &Ogre::OverlayContainer::addChild)

					  ];
}
#endif
int addItemRecursive(int curItem, bool bSubMenu, FlMenu & menu, luabind::object const& ll)
{
	for(luabind::iterator i(ll), end; i!=end; ++i)
		{
			if(luabind::type(*i)!=LUA_TTABLE)
				{
					const char* menuTitle=luabind::object_cast<const char*>(*i);
					if(bSubMenu )
						menu.item(curItem, menuTitle, 0,0, FL_SUBMENU);
					else
						menu.item(curItem, menuTitle);

					curItem++;
				}
			else
				{
					curItem=addItemRecursive(curItem, true, menu, *i);
					menu.item(curItem, 0);	// submenu닫기.
					curItem++;
				}

			bSubMenu=false;
		}
	return curItem;
}



#include "mainliblua_wrap.h"
Viewpoint* RE_::getViewpoint()
{
  return RE::renderer().viewport().m_pViewpoint;
}

std::string RE_::generateUniqueName()
{
  return std::string(RE::generateUniqueName().ptr());
}

Ogre::Entity* RE_::createPlane2(const char* id, m_real width, m_real height, int xsegment, int ysegment, int texSegx, int texSegy)
{
  return RE::createPlane(id, width, height, xsegment, ysegment, texSegx, texSegy);
}

Ogre::Entity* RE_::createPlane(const char* id, m_real width, m_real height, int xsegment, int ysegment)
{
  return createPlane2(id, width, height, xsegment, ysegment, 1, 1);
}

void RE_::setBackgroundColour(m_real r, m_real g, m_real b)
{
#ifndef NO_OGRE

  RE::renderer().viewport().mView->setBackgroundColour(Ogre::ColourValue(r,g,b,1.f));
#endif
}
void RE_::remove(PLDPrimSkin* p)
{
  printf("remove is deprecated. (Calling this is no longer needed as the object is owned by LUA).\n");
  //RE::remove(p);
}
void RE_::renderOneFrame(bool check)
{
  if(!RE::rendererValid() ) return;

#ifndef NO_GUI
  if(check)
	{
	  if(RE::FltkRenderer().visible())
		{
		  while(!Fl::check()) ;
		}else{
		while(!Fl::wait()) ;
	  }
	}
#endif
				

  RE::renderer().renderOneFrame();
}

PLDPrimSkin* RE_::createSkin2(const MotionLoader& skel, int typet)
{
  return RE::createSkin(skel, (RE::PLDPrimSkinType)typet);
}

PLDPrimSkin* RE_::createSkin3(const Motion& mot, int typet)
{
  return RE::createSkin(mot, (RE::PLDPrimSkinType)typet);
}


void addMainlibModule(lua_State* L)
{
	// FlLayout
	{
		Fl_Widget* (FlLayout::*create1)(const char* type, const char* id, const char* title)=&FlLayout::create;
		Fl_Widget* (FlLayout::*create2)(const char* type, const char* id, const char* title, int startSlot, int endSlot, int height)=&FlLayout::create;
		struct FlLayout_
		{
			static void create3(FlLayout* l,const char* type, const char* id, const char* title, int startSlot)
			{
				l->create(type, id, title, startSlot);
			}
			static void create4(FlLayout* l,const char* type, const char* id, const char* title, int startSlot, int endSlot)
			{
				l->create(type, id, title, startSlot, endSlot);
			}
			static void create5(FlLayout* l,const char* type, const char* id)
			{
				l->create(type, id);
			}

		};
		module(L)[
				  def("FastCapture_convert", &FastCapture_convert),

				  class_<FlLayout>("FlLayout")
				  .def("begin", &FlLayout::begin)
				  .def("create", create1, discard_result)
				  .def("create", create2, discard_result)
				  .def("create", &FlLayout_::create3)
				  .def("create", &FlLayout_::create4)
				  .def("create", &FlLayout_::create5)
				  .def("newLine", &FlLayout::newLine)
				  .def("embedLayout", &FlLayout::embedLayout)
				  .def("setLineSpace", &FlLayout::setWidgetHeight)
				  .def("setWidgetPos", &FlLayout::setWidgetPos)
				  .def("setUniformGuidelines", &FlLayout::setUniformGuidelines)
				  .def("updateLayout", &FlLayout::updateLayout)
				  .def("redraw", &FlLayout::redraw)
				  .def("minimumHeight", &FlLayout::minimumHeight)
				  .def("widget", &FlLayout::widgetRaw)
				  .def("widgetIndex", &FlLayout::widgetIndex)
				  .def("findWidget", &FlLayout::findWidget)
				  .def("callCallbackFunction", &FlLayout::callCallbackFunction)
				  .def("__call", &FlLayout::__call)
			  
				  ];
	}

	// FlLayout::Widget
	{
		struct FlLayoutWidget_
		{
			static void checkButtonValue(FlLayout::Widget& w, int value)
			{
				w.checkButton()->value(value);
			}
			static void checkButtonValue3(FlLayout::Widget& w, bool value)
			{
				w.checkButton()->value(value);
			}
			static bool checkButtonValue2(FlLayout::Widget& w)
			{
				return w.checkButton()->value();
			}
			static void menuSize(FlLayout::Widget& w,int nsize)
			{
				w.menu()->size(nsize);
			}
			static void menuItem(FlLayout::Widget& w,int i, const char* title)
			{
				w.menu()->item(i, title);
			}
			static void menuItem2(FlLayout::Widget& w,int i, const char* title, const char* shortc)
			{
				w.menu()->item(i, title, FlGenShortcut(shortc));
			}
			static void menuValue(FlLayout::Widget& w, int v)
			{
				w.menu()->value(v);
			}
			static std::string menuText(FlLayout::Widget& w, int v)
			{
#ifndef NO_GUI
				return w.menu()->text(v);
#else
				return "";
#endif
					
			}
			static std::string menuText2(FlLayout::Widget& w)
			{
#ifndef NO_GUI
				return w.menu()->text();
#else
				return "";
#endif
			}
			static int menuValue2(FlLayout::Widget& w)
			{
				return w.menu()->value();
			}
			static void sliderValue(FlLayout::Widget& w, double v)
			{
				w.slider()->value(v);
			}
			static void sliderStep(FlLayout::Widget& w, double v)
			{
#ifndef NO_GUI
				w.slider()->step(v);
#endif
			}
			static void sliderRange(FlLayout::Widget& w, double v1, double v2)
			{
#ifndef NO_GUI
				w.slider()->range(v1, v2);
#endif
			}
			static double sliderValue2(FlLayout::Widget& w)
			{
				return w.slider()->value();
			}
			static void buttonShortcut(FlLayout::Widget& w, const char* s)
			{
#ifndef NO_GUI				
				w.button()->shortcut(FlGenShortcut(s));
				w.button()->tooltip(s);
#endif
			}
			static const char* id(FlLayout::Widget& w)
			{
				return w.mId;
			}
			static int browserSize(FlLayout::Widget& w)
			{
#ifndef NO_GUI
				Fl_Browser* browser=w.widget<Fl_Browser>();
				return browser->size();
#else
				return 0;
#endif
			}
			static bool browserSelected(FlLayout::Widget& w, int i)
			{
#ifndef NO_GUI
				Fl_Browser* browser=w.widget<Fl_Browser>();
				return browser->selected(i);
#else
				return false;
#endif
			}

			static void browserDeselect(FlLayout::Widget& w)
			{
#ifndef NO_GUI
				Fl_Browser* browser=w.widget<Fl_Browser>();
				browser->deselect();
#endif
			}
			static void browserSelect(FlLayout::Widget& w,int i)
			{
#ifndef NO_GUI
				Fl_Browser* browser=w.widget<Fl_Browser>();
				browser->select(i);
#endif
			}
			static void browserAdd(FlLayout::Widget& w, const char* name)
			{
#ifndef NO_GUI
				Fl_Browser* browser=w.widget<Fl_Browser>();
				browser->add(name,NULL);
#endif
			}
			static void browserClear(FlLayout::Widget& w)
			{
#ifndef NO_GUI
				Fl_Browser* browser=w.widget<Fl_Browser>();
				browser->clear();
#endif
			}
			static void inputValue1(FlLayout::Widget& w, const char* text)
			{
#ifndef NO_GUI
				Fl_Input* input=w.widget<Fl_Input>();
				input->value(text);
#endif
			}
			static std::string inputValue2(FlLayout::Widget& w)
			{
				std::string str;
#ifndef NO_GUI
				Fl_Input* input=w.widget<Fl_Input>();
				str=input->value();
#endif
				return str;
			}


		};

		module(L)[class_<FlLayout::Widget>("FlLayoutWidget")
				  .def("id", FlLayoutWidget_::id)
				  .def("checkButtonValue", FlLayoutWidget_::checkButtonValue)
				  .def("checkButtonValue", FlLayoutWidget_::checkButtonValue2)
				  .def("checkButtonValue", FlLayoutWidget_::checkButtonValue3)
				  .def("buttonShortcut", FlLayoutWidget_::buttonShortcut)
				  .def("menuSize", FlLayoutWidget_::menuSize)
				  .def("menuItem", FlLayoutWidget_::menuItem)
				  .def("menuItem", FlLayoutWidget_::menuItem2)
				  .def("menuValue", FlLayoutWidget_::menuValue)
				  .def("menuValue", FlLayoutWidget_::menuValue2)
				  .def("sliderValue", FlLayoutWidget_::sliderValue)
				  .def("sliderValue", FlLayoutWidget_::sliderValue2)
				  .def("sliderStep", FlLayoutWidget_::sliderStep)
				  .def("sliderRange", FlLayoutWidget_::sliderRange)
				  .def("browserSize", FlLayoutWidget_::browserSize)
				  .def("browserClear", FlLayoutWidget_::browserClear)
				  .def("browserSelected", FlLayoutWidget_::browserSelected)
				  .def("browserDeselect", FlLayoutWidget_::browserDeselect)
				  .def("browserSelect", FlLayoutWidget_::browserSelect)
				  .def("browserAdd", FlLayoutWidget_::browserAdd)
				  .def("inputValue", FlLayoutWidget_::inputValue1)
				  .def("inputValue", FlLayoutWidget_::inputValue2)
				  .def("menuText", FlLayoutWidget_::menuText)
.def("menuText", FlLayoutWidget_::menuText2)	
				  ];

	}

	// FlMenu
	{
		struct FlMenu_
		{
			static void addItem(FlMenu* pMenu, luabind::object const& table)
			{
				int numMenuItems=LUAwrapper::treeSize(table)-1;
				pMenu->size(numMenuItems);
				int item=addItemRecursive(0, false, *pMenu, table);
				ASSERT(item==numMenuItems);
			}
		};
		module(L)[class_<FlMenu>("FlMenu")
				  .def("addItem", &FlMenu_::addItem)
				  ];
	}

	// Viewpoint
	{
		struct Viewpoint_
		{
			static void update(Viewpoint & view)
			{
				view.CalcHAngle();
				view.CalcVAngle();
				view.CalcDepth();
			}

			static void setClipDistances(Viewpoint& view, m_real fnear, m_real ffar)
			{
#ifndef NO_OGRE

				double nn=fnear;
				double ff=ffar;
				RE::renderer().viewport().mCam->setNearClipDistance(Ogre::Real(fnear));
				RE::renderer().viewport().mCam->setFarClipDistance(Ogre::Real(ffar));
#endif
			}

			static void setFOVy(Viewpoint& view, m_real degree)
			{
#ifndef NO_OGRE

				RE::renderer().viewport().mCam->setFOVy(Ogre::Radian(Ogre::Degree(degree)));
#endif
			}

		};
		module(L)[class_<Viewpoint>("Viewpoint")
				  .def_readwrite("vpos", &Viewpoint::m_vecVPos)
				  .def_readwrite("vat", &Viewpoint::m_vecVAt)
				  .def("update", &Viewpoint_::update)
				  .def("setClipDistances", &Viewpoint_::setClipDistances)
				  .def("setFOVy", &Viewpoint_::setFOVy)
				  .def("setScale", &Viewpoint::setScale)
				  .def("updateVPosFromVHD", &Viewpoint::UpdateVPosFromVHD)
				  .def("TurnRight", &Viewpoint::TurnRight)
				  .def("TurnLeft", &Viewpoint::TurnLeft)
				  .def("TurnUp", &Viewpoint::TurnUp)
				  .def("TurnDown", &Viewpoint::TurnDown)
				  .def("ZoomIn", &Viewpoint::ZoomIn)
				  .def("ZoomOut", &Viewpoint::ZoomOut)
				  ];

		struct FLTK_
		{
			static std::string chooseFile(const char* msg, const char* path, const char* mask, bool bCreate)
			{
#ifndef NO_GUI
				TString temp=FlChooseFile(msg,path,mask,bCreate).ptr();
				if(temp.length())
					return std::string(temp.ptr());
#endif
				return std::string("");
			}

			static bool ask(const char* msg)
			{ 
#ifndef NO_GUI

				return fl_ask("%s", msg);
#else
				return true;
#endif
			}
		};
		module(L, "Fltk")[
						  def("chooseFile", &FLTK_::chooseFile)
						  ,def("ask", &FLTK_::ask)
						  ];
	}

	// Renderer
	{

		module(L)[class_<OgreRenderer>("OgreRenderer")
				  .def("screenshot", &OgreRenderer::screenshot)
				  .def("setScreenshotPrefix", &OgreRenderer::setScreenshotPrefix)
				  .def("fixedTimeStep", &OgreRenderer::fixedTimeStep)
				  .def("setCaptureFPS", &OgreRenderer::setCaptureFPS)
				  ];

		module(L)[class_<FltkRenderer>("FltkRenderer")
				  .def("screenToWorldXZPlane", &FltkRenderer::screenToWorldXZPlane)
				  ];
	}

	// Mesh
	{
		module(L)[class_<OBJloader::Mesh>("Mesh")
				  .def(constructor<>())
				  .def("numFace", &OBJloader::Mesh::numFace)
				  .def("getFace", (OBJloader::Face & (OBJloader::Mesh::*)(int i))&OBJloader::Mesh::getFace)
				  .def("numVertex",&OBJloader::Mesh::numVertex)
				  .def("getVertex", (vector3 & (OBJloader::Mesh::*)(int i))&OBJloader::Mesh::getVertex)
				  .def("loadOBJ", &OBJloader::Mesh::loadObj)
				  .def("saveOBJ", &OBJloader::Mesh::saveObj)
				  .def("transform", &OBJloader::Mesh::transform)
				  .def("createBox", &OBJloader::createBox)
				  .def("assign", &OBJloader::Mesh::copyFrom)
				  .def("merge", &OBJloader::Mesh::merge)
				  .def("createCylinder", &OBJloader::createCylinder)
				  ];
	}
	// PLDPrimSkin
	{
		struct PLDPrimSkin_
		{
			static void scale(PLDPrimSkin& s, double x, double y, double z)
			{
#ifndef NO_OGRE

				s.m_pSceneNode->scale(x,y,z);
#endif
			}
			static void setRotation(PLDPrimSkin& s,quater const& q)
			{
#ifndef NO_OGRE
				s.m_pSceneNode->setOrientation(ToOgre(q));
#endif
			}
			static void startAnim(PLDPrimSkin& s)
			{
				s.m_pTimer->StartAnim();
			}

		};
		module(L)[
				  class_<AnimationObject>("AnimationObject"),
				  class_<PLDPrimSkin,AnimationObject>("PLDPrimSkin")
				  .property("visible", &PLDPrimSkin::GetVisible, &PLDPrimSkin::SetVisible)
				  .def("setTranslation",&PLDPrimSkin::SetTranslation)
				  .def("setPose", 	(void (PLDPrimSkin::*)(const Motion& mot, int iframe))&PLDPrimSkin::setPose)
				  .def("setPose", 	(void (PLDPrimSkin::*)(int iframe))&PLDPrimSkin::setPose)
				  .def("setPose", 	(void (PLDPrimSkin::*)(const Posture & posture, const MotionLoader& skeleton))&PLDPrimSkin::SetPose)
				  .def("applyAnim", &PLDPrimSkin::ApplyAnim)
				  .def("startAnim", &PLDPrimSkin_::startAnim)
				  .def("setThickness", &PLDPrimSkin::setThickness)
				  .def("scale", &PLDPrimSkin_::scale)
				  .def("setRotation", &PLDPrimSkin_::setRotation)
				  .def("setVisible", &PLDPrimSkin::SetVisible)
				  .enum_("constants")
				  [
				   value("BLOB",(int)RE::PLDPRIM_BLOB),
				   value("LINE",(int)RE::PLDPRIM_LINE),
				   value("SKIN",(int)RE::PLDPRIM_SKIN),
				   value("POINT",(int)RE::PLDPRIM_POINT),
				   value("CYLINDER",(int)RE::PLDPRIM_CYLINDER),
				   value("CYLINDER_LOWPOLY, ",(int)RE::PLDPRIM_CYLINDER_LOWPOLY),
				   value("BOX",(int)RE::PLDPRIM_BOX)
				   ]
				  ];
	}
	// MotionPanel
	{
#ifndef NO_GUI
		struct MotionPanel_
		{
			static void drawCon(MotionPanel& mp, int eCon)
			{
				Motion& curMot=mp.currMotion();
				MotionUtil::GetSignal gs(curMot);
				bitvectorn con;
				gs.constraint(eCon, con);
				RE::motionPanel().scrollPanel()->addPanel(con, CPixelRGB8 (255,0, 255));

				for(int i=0; i<mp.motionWin()->getNumSkin(); i++)
					{
						PLDPrimSkin* pSkin=((PLDPrimSkin*)mp.motionWin()->getSkin(i));
						pSkin->setDrawConstraint(eCon, 4, RE::RED);
						pSkin->setDrawOrientation(0);
					}
			}
		};


		module(L)[class_<CPixelRGB8>("CPixelRGB8")
				  .def(constructor<>())
				  .def(constructor<uchar, uchar, uchar>())
				  .def_readwrite("R", &CPixelRGB8::R)
				  .def_readwrite("G", &CPixelRGB8::G)
				  .def_readwrite("B", &CPixelRGB8::B)];


		module(L)[class_<FltkScrollPanel>("FltkScrollPanel")
				  .def("addPanel", (void (FltkScrollPanel::*)(const char*))&FltkScrollPanel::addPanel)
				  .def("addPanel", (void (FltkScrollPanel::*)(const bitvectorn& bits, CPixelRGB8 color))&FltkScrollPanel::addPanel)
				  .def("addPanel", (void (FltkScrollPanel::*)(CImage* ))&FltkScrollPanel::addPanel)
				  .def("setLabel", &FltkScrollPanel::setLabel)
				  .def("setCutState", &FltkScrollPanel::setCutState)
				  .def("removeAllPanel", &FltkScrollPanel::removeAllPanel)
				  .def("redraw", &FltkScrollPanel::redraw)
				  .def("currFrame", &FltkScrollPanel::currFrame),

				  class_<FltkScrollSelectPanel>("SelectPanel")
				  .def(constructor<>())
				  .def("isCreated", &FltkScrollSelectPanel::isCreated)
				  .def("init", &FltkScrollSelectPanel::init)
				  .def("release", &FltkScrollSelectPanel::release)
				  .def("drawBoxColormap",&FltkScrollSelectPanel::drawBoxColormap)
				  .def("drawBox",&FltkScrollSelectPanel::drawBox)
				  .def("drawFrameLines",&FltkScrollSelectPanel::drawFrameLines)
				  .def("drawTextBox",&FltkScrollSelectPanel::drawTextBox)
				  .def("clear",&FltkScrollSelectPanel::clear),

				  class_<MotionPanel>("MotionPanel")
				  .def("motionWin", &MotionPanel::motionWin)
				  .def("scrollPanel", &MotionPanel::scrollPanel)
				  .def("loader", &MotionPanel::loader)
				  .def("currMotion", &MotionPanel::currMotion)
				  .def("registerMotion", &MotionPanel::registerMotion)
				  .def("releaseMotions", &MotionPanel::releaseMotions)
				  .def("drawCon", &MotionPanel_::drawCon)
				  .def("redraw", &MotionPanel::redraw),

				  class_<FltkMotionWindow >("FltkMotionWindow")
				  .def("changeCurrFrame", &FltkMotionWindow::changeCurrFrame)
				  .def("getCurrFrame", &FltkMotionWindow::getCurrFrame)
				  .def("addSkin", &FltkMotionWindow ::addSkin)
				  .def("releaseAllSkin", &FltkMotionWindow ::releaseAllSkin)
				  .def("releaseSkin", &FltkMotionWindow ::releaseSkin)
				  .def("detachAllSkin", &FltkMotionWindow ::detachAllSkin)
				  .def("detachSkin", &FltkMotionWindow ::detachSkin)

				  ];
		
		module(L)
			[
			 class_<FltkMotionWindow ::EventReceiver, EventReceiver_wrapper>("EventReceiver")
			 .def(constructor<>())
			 .def("onNext", &FltkMotionWindow ::EventReceiver::OnNext, &EventReceiver_wrapper::default_on)
			 .def("onPrev", &FltkMotionWindow ::EventReceiver::OnPrev, &EventReceiver_wrapper::default_op)
			 .def("onFrameChanged", &FltkMotionWindow ::EventReceiver::OnFrameChanged, &EventReceiver_wrapper::default_ofc)
			 .def("frameMove", &EventReceiver_wrapper::FrameMove, &EventReceiver_wrapper::default_fm),
			 class_<FltkScrollPanel::SelectUI, SelectUI_wrapper>("SelectUI")
			 .def(constructor<>())
			 .def("click", &FltkScrollPanel::SelectUI::click, &SelectUI_wrapper::click)
			 .def("selected", &FltkScrollPanel::SelectUI::selected, &SelectUI_wrapper::selected)
			 .def("panelSelected", &FltkScrollPanel::SelectUI::panelSelected, &SelectUI_wrapper::panelSelected)
			 ];
#else
		module(L)
			[
			 class_<EventReceiver_wrapper>("EventReceiver")
			 .def(constructor<>())
			 .def("frameMove", &EventReceiver_wrapper::FrameMove, &EventReceiver_wrapper::default_fm)
			];
#endif

		module(L)
			[
			 class_<RendererEventHandler>("RendererEventHandler")
			 .def(constructor<>())
			 .enum_("constants")
			 [
			  value("FL_PUSH",(int)FL_PUSH),
			  value("FL_MOVE",(int)FL_MOVE),
			  value("FL_DRAG",(int)FL_DRAG),
			  value("FL_RELEASE",(int)FL_RELEASE)
			  ]
			 ];
		
	}
	{

		module(L, "RE")[
						def("ogreSceneManager", &RE::ogreSceneManager),
						def("_output", &RE_outputRaw),
						def("dumpOutput", &RE_dumpOutput),
						def("outputEraseAll", &RE_outputEraseAll),
						def("outputState", &RE::outputState),
						def("motionLoader", &RE::motionLoader),
						def("ogreRootSceneNode", &RE::ogreRootSceneNode),
						def("createChildSceneNode", &RE::createChildSceneNode),
						def("createFrameSensor", &RE::createFrameSensor),
						def("generateUniqueName", &RE_::generateUniqueName),
						def("createSkin", (PLDPrimSkin* (*)(const Motion&))&RE::createSkin, luabind::adopt(luabind::result)),
						def("createSkin", (PLDPrimSkin* (*)(const MotionLoader&))&RE::createSkin,luabind::adopt(luabind::result)),
						def("createSkin", &RE_::createSkin2,luabind::adopt(luabind::result)),
						def("createSkin", &RE_::createSkin3,luabind::adopt(luabind::result)),
						def("remove", &RE_::remove),
						def("createEntity", (Ogre::SceneNode* (*)(const char* id, const char* filename))&RE::createEntity),
						def("removeEntity", (void (*)(Ogre::SceneNode*))&RE::removeEntity),
						def("setMaterialName", &RE::setMaterialName),
						def("moveEntity", (void (*)(Ogre::SceneNode*, quater const&, vector3 const&))&RE::moveEntity),
						def("createPlane", &RE_::createPlane),
						def("createTerrain", &RE::createTerrain),
						def("createPlane", &RE_::createPlane2),
						def("setBackgroundColour", &RE_::setBackgroundColour),
						def("viewpoint", &RE_::getViewpoint),
#ifndef NO_GUI

						def("motionPanel",&RE::motionPanel)	,
#endif
						def("motionPanelValid",&RE::motionPanelValid)	,
						def("rendererValid",&RE::rendererValid)	,
						def("renderer", &RE::renderer),
						def("FltkRenderer", &RE::FltkRenderer),
						def("renderOneFrame", &RE_::renderOneFrame)

						];
	}
	// namespace Ogre
	{
		class SceneNode_
		{
		public:
			static void resetToInitialState(Ogre::SceneNode* pNode)
			{OGRE_VOID(pNode->resetToInitialState());}
			static void removeAndDestroyChild(Ogre::SceneNode* pNode, const char* name)
			{OGRE_VOID(pNode->removeAndDestroyChild(name));}
			static Ogre::SceneNode* createChildSceneNode(Ogre::SceneNode* pNode, const char* name)
			{OGRE_PTR(return pNode->createChildSceneNode(name));}
			static Ogre::SceneNode* createChildSceneNode2(Ogre::SceneNode* pNode)
			{OGRE_PTR(return pNode->createChildSceneNode());}
			static void translate(Ogre::SceneNode* pNode, vector3 const& t)
			{OGRE_VOID(pNode->translate(t.x, t.y, t.z));}
			static void rotate(Ogre::SceneNode* pNode, quater const& t)
			{OGRE_VOID(pNode->rotate(ToOgre(t)));}
			static void translate2(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->translate(x, y, z));}
			static void scale(Ogre::SceneNode* pNode, vector3 const& t)
			{OGRE_VOID(pNode->scale(t.x, t.y, t.z));}
			static void scale2(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->scale(x, y, z));}

			static void setPosition(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->setPosition(x,y,z));}
			static void setPosition2(Ogre::SceneNode* pNode, vector3 const& t)
			{OGRE_VOID(pNode->setPosition(t.x,t.y,t.z));}
			static void setScale(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->setScale(x,y,z));}
			static void setScaleAndPosition(Ogre::SceneNode* pNode, vector3 const& s, vector3 const& t)
			{OGRE_VOID(pNode->setScale(s.x,s.y,s.z);pNode->setPosition(t.x,t.y,t.z));}
			static void setOrientation(Ogre::SceneNode* pNode, m_real w, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->setOrientation(w, x,y,z));}
			static void setOrientation2(Ogre::SceneNode* pNode, quater const& q)
			{OGRE_VOID(pNode->setOrientation(q.w, q.x,q.y,q.z));}
		};

		class SceneManager_
		{
		public:
			static Ogre::Entity* createEntity(Ogre::SceneManager* pmgr, const char* id, const char* mesh)
			{
#ifndef NO_OGRE
				BEGIN_OGRE_CHECK
					return pmgr->createEntity(id,mesh);
				END_OGRE_CHECK
#else 
					return NULL;
#endif
			}

			static Ogre::SceneNode* getSceneNode(Ogre::SceneManager* pmgr, const char* id)
			{
#ifndef NO_OGRE
				BEGIN_OGRE_CHECK
					return pmgr->getSceneNode(id);
				END_OGRE_CHECK
#else 
					return NULL;
#endif

			}

			static Ogre::Light* createLight(Ogre::SceneManager* pmgr, const char* id)
			{
#ifndef NO_OGRE
				BEGIN_OGRE_CHECK
					return pmgr->createLight(id);

				END_OGRE_CHECK
#else 
					return NULL;
#endif


			}

			static void setAmbientLight(Ogre::SceneManager* pmgr, m_real x, m_real y, m_real z)
			{OGRE_VOID(pmgr->setAmbientLight(Ogre::ColourValue(x,y,z)));}

			static void setSkyBox(Ogre::SceneManager* pmgr, bool enable, const char* materialName)
			{OGRE_VOID(pmgr->setSkyBox(enable, materialName));}

		};

		module(L, "Ogre")[
						  class_<intersectionTest::LineSegment>("LineSegment")
						  .def(constructor<const vector3&, const vector3&>())
						  .def("origin", &intersectionTest::LineSegment::origin)
						  .def("dir", &intersectionTest::LineSegment::dir)
						  .def("length", &intersectionTest::LineSegment::length)
						  .def("pos", &intersectionTest::LineSegment::pos)
						  .def("target", &intersectionTest::LineSegment::target)
						  .def("minDist", &intersectionTest::LineSegment::minDist)
						  .def("minDistTime", &intersectionTest::LineSegment::minDistTime),



						  class_<Ogre::SceneNode>("SceneNode")
						  .def("removeAndDestroyChild", &SceneNode_::removeAndDestroyChild)
						  .def("createChildSceneNode",&SceneNode_::createChildSceneNode)
						  .def("createChildSceneNode",&SceneNode_::createChildSceneNode2)
						  .def("translate", &SceneNode_::translate)
						  .def("translate", &SceneNode_::translate2)
						  .def("rotate", &SceneNode_::rotate)
						  .def("scale", &SceneNode_::scale)
						  .def("scale", &SceneNode_::scale2)
						  .def("setPosition", &SceneNode_::setPosition)
						  .def("setPosition", &SceneNode_::setPosition2)
						  .def("setScaleAndPosition", &SceneNode_::setScaleAndPosition)
						  .def("setScale", &SceneNode_::setScale)
						  .def("resetToInitialState", &SceneNode_::resetToInitialState)
						  .def("setOrientation", &SceneNode_::setOrientation)
						  .def("setOrientation", &SceneNode_::setOrientation2)
#ifndef NO_OGRE
						  .def("attachObject", &Ogre::SceneNode::attachObject)
						  .def("numAttachedObjects", &Ogre::SceneNode::numAttachedObjects)
#endif
						  ,
						  class_<Ogre::SceneManager>("SceneManager")
						  .def("createEntity", &SceneManager_::createEntity)
						  .def("getSceneNode", &SceneManager_::getSceneNode)
						  .def("createLight", &SceneManager_::createLight)
						  .def("setAmbientLight", &SceneManager_::setAmbientLight)
						  .def("setSkyBox", &SceneManager_::setSkyBox),
						  class_<ObjectList>("ObjectList")
						  .def(constructor<>())
						  .def("clear", &ObjectList::clear)
						  .def("setVisible", &ObjectList::setVisible)
						  .def("registerEntity", (Ogre::SceneNode* (ObjectList::*)(const char* , const char* ))&ObjectList::registerEntity)
						  .def("registerEntity", (Ogre::SceneNode* (ObjectList::*)(const char* , const char* , const char*))&ObjectList::registerEntity)
						  .def("registerEntityScheduled", (Ogre::SceneNode* (ObjectList::*)(const char* , m_real ))&ObjectList::registerEntityScheduled)
						  .def("registerObject", (Ogre::SceneNode* (ObjectList::*)(const char* , const char* , const char* , matrixn const& , m_real ))&ObjectList::registerObject)
						  .def("findNode", &ObjectList::findNode)
						  .def("erase", &ObjectList::erase)
						  .def("eraseAllScheduled", &ObjectList::eraseAllScheduled)
						  ];

#ifndef NO_OGRE
		addOverlay(L);
#endif
		struct Entity_
		{
			static void setNormaliseNormals(Ogre::Entity& e)
			{
				// do nothing.
			}

			static void setMaterialName(Ogre::Entity& e, const char* matName)
			{
#ifndef NO_OGRE
				e.setMaterialName(matName);
#endif
			}
		};
		module(L, "Ogre")[
						  class_<Ogre::MovableObject>("MovableObject"),

						  class_<Ogre::Entity, bases<Ogre::MovableObject> >("Entity")
#ifndef NO_OGRE
						  .def("setCastShadows", &Ogre::Entity::setCastShadows)
						  .def("setMaterialName", &Entity_::setMaterialName)
#endif
						  .def("setNormaliseNormals", &Entity_::setNormaliseNormals)
						  ];
#ifndef NO_OGRE
		// Light
		struct Light_
		{
			static void setType(Ogre::Light* light, const char* type)
			{
				TString t=type;
				if(t=="LT_DIRECTIONAL")
					light->setType(Ogre::Light::LT_DIRECTIONAL);
				else if(t=="LT_POINT")
					light->setType(Ogre::Light::LT_POINT);
				else
					light->setType(Ogre::Light::LT_SPOTLIGHT);
			}

			static void setDirection(Ogre::Light* light, m_real x, m_real y, m_real z)
			{light->setDirection(Ogre::Vector3(x,y,z));}
			static void setPosition(Ogre::Light* light, m_real x, m_real y, m_real z)
			{light->setPosition(x,y,z);}
			static void setDiffuseColour(Ogre::Light* light, m_real x, m_real y, m_real z)
			{light->setDiffuseColour(Ogre::ColourValue(x,y,z));}
			static void setSpecularColour(Ogre::Light* light, m_real x, m_real y, m_real z)
			{light->setSpecularColour(Ogre::ColourValue(x,y,z));}

		};
		module(L, "Ogre")[
						  class_<Ogre::Light, bases<Ogre::MovableObject> >("Light")
						  .def("setType", &Light_::setType)
						  .def("setDirection", &Light_::setDirection)
						  .def("setPosition", &Light_::setPosition)
						  .def("setDiffuseColour", &Light_::setDiffuseColour)
						  .def("setSpecularColour", &Light_::setSpecularColour)
						  .def("setCastShadows", &Ogre::Light::setCastShadows)
						  ];

#endif
	}

	luabind::bind_class_info(L); 
}


void saveViewpoint(FILE* file)
{
#ifdef NO_OGRE
	double fov=45;
#else
	double fov=RE::renderer().viewport().mCam->getFOVy().valueDegrees();
#endif
	fprintf(file, "RE.viewpoint():setFOVy(%f)\n", fov);
	vector3 v=RE::renderer().viewport().m_pViewpoint->m_vecVPos;
	fprintf(file, "RE.viewpoint().vpos:assign({%f, %f, %f})\n", v.x, v.y, v.z);
	v=RE::renderer().viewport().m_pViewpoint->m_vecVAt;
	fprintf(file, "RE.viewpoint().vat:assign({%f, %f, %f})\n", v.x, v.y, v.z);
	fprintf(file, "RE.viewpoint():update()\n\n");
}
