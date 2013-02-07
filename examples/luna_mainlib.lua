
array.pushBack(gen_lua.enum_types, 'RE::PLDPrimSkinType') 
array.pushBack(gen_lua.number_types, 'ushort') 
array.pushBack(gen_lua.number_types, 'uint') 
array.pushBack(gen_lua.number_types, 'Ogre::Real') 

bindTargetMainLib={
	namespaces={
		MainLib={
			'VRMLloader','VRMLloaderView'
		}
	},
	classes={

		{
			name='SelectPanel',
			decl='class FltkScrollSelectPanel;',
			className='FltkScrollSelectPanel',
			ifndef='NO_GUI',
			ctors={'()'},
			memberFunctions={[[
			bool isCreated()	
			void init(MotionPanel* pPanel, const char* label, int height, int maxValue);
			void release(MotionPanel* pPanel);
			void drawBoxColormap(int start, int end, int colormapValue);
			void drawBox(int start, int end, CPixelRGB8  color);
			void drawFrameLines(intvectorn const& frames);
			void drawTextBox(int start, int end, int colormapValue, const char* text);
			void clear(int start, int end);
			]]}
		},
		{
			name='EventReceiver',
			className='EventReceiver_lunawrapper',
			decl='class EventReceiver_lunawrapper;',
			isLuaInheritable=true,
			globalWrapperCode=[[
#ifdef NO_GUI
struct EventReceiver_lunawrapper: FrameMoveObject, public luna_wrap_object
{
	EventReceiver_lunawrapper()
	{
		RE::renderer().addFrameMoveObject(this);
	}

	virtual ~EventReceiver_lunawrapper()
	{
		RE::renderer().removeFrameMoveObject(this);
	}

	virtual int FrameMove(float fElapsedTime)  {
		lunaStack l(_L);
		if(pushMemberFunc<EventReceiver_lunawrapper>(l,"frameMove")){
			l<<(double)fElapsedTime;
			l.call(2,0);
		} 
		return 1;
	}
};
#else
struct EventReceiver_lunawrapper: FltkMotionWindow ::EventReceiver, FrameMoveObject , public luna_wrap_object
{
	EventReceiver_lunawrapper()
		: FltkMotionWindow ::EventReceiver()
	{
		RE::motionPanel().motionWin()->connect(*this);
		RE::renderer().addFrameMoveObject(this);
	}

	virtual ~EventReceiver_lunawrapper()
	{
		RE::motionPanel().motionWin()->disconnect(*this);
		RE::renderer().removeFrameMoveObject(this);
	}

	virtual void OnNext(FltkMotionWindow* win)
	{
		lunaStack l(_L);
		if(pushMemberFunc<EventReceiver_lunawrapper>(l, "onNext")){
			l.push<FltkMotionWindow>(win);
			l.call(2,0);
		}
	}
	virtual void OnPrev(FltkMotionWindow* win)
	{
		lunaStack l(_L);
		if(pushMemberFunc<EventReceiver_lunawrapper>(l, "onPrev")){
			l.push<FltkMotionWindow>(win);
			l.call(2,0);
		}
	}
	virtual void OnFrameChanged(FltkMotionWindow* win, int i)
	{
		lunaStack l(_L);
		if(pushMemberFunc<EventReceiver_lunawrapper>(l,"onFrameChanged")){
			l.push<FltkMotionWindow>(win);
			l<<(double)i;
			l.call(3,0);
		} 
	}
	virtual int FrameMove(float fElapsedTime)
	{
		lunaStack l(_L);
		if(pushMemberFunc<EventReceiver_lunawrapper>(l, "frameMove")){
			l<<(double)fElapsedTime;
			l.call(2,0);
		}
		return 1;
	}
};
#endif
			]],
			ctors={'()'},
		},
		{
			name='Fltk.ChoiceWins',
			className='FlChoiceWins',
			wrapperCode=[[
			static FlChoiceWins* choiceWin(FlChoiceWins* win, int i)
			{
				return dynamic_cast<FlChoiceWins*>(win->window(i));
			}

			static FlLayout* layout(FlChoiceWins* win, int i)
			{
				return static_cast<FlLayout*>(win->window(i));
			}
			]],
			properties={'TStrings windowNames;'},
			memberFunctions={
				[[
				void show(int)
				]]
			},
			staticMemberFunctions={
				[[
				static FlChoiceWins* choiceWin(FlChoiceWins* win, int i)
				static FlLayout* layout(FlChoiceWins* win, int i)
				]]
			}
		},
		{
			name='math.Point2D',
			className='std::pair<double,double>',
			ctors={'()','(double,double)'},
			properties={'double first @ x', 'double second @ y'},
		},
		{
			name='math.vecPoint2D',
			className='std::vector<std::pair<double,double> >'
		},
		{
			name='MeshToEntity',
			className='OBJloader::MeshToEntity',
			ctors={'(const OBJloader::Mesh& mesh, const char* ogreMeshName)'},
			memberFunctions={[[
			void updatePositions();
			void updatePositionsAndNormals();
			Ogre::Entity* createEntity(const char* entityName);
			Ogre::Entity* createEntity(const char* entityName, const char* materialName);
			Ogre::Entity* getLastCreatedEntity() const
			]] }
		},
		{
			name='Mesh',
			className='OBJloader::Mesh',
			ctors={'()'},
			memberFunctions={[[
				int numFace() const 
				OBJloader::Face & getFace(int i)
				int numVertex() const;
				vector3& getVertex(int i);
				bool saveObj(const char* filename, bool vn, bool vt); @ saveOBJ
				bool loadObj(const char* filename); @ loadOBJ
				void copyFrom(OBJloader::Mesh const& otherMesh); @ assign
				void merge(OBJloader::Mesh const& a, OBJloader::Mesh const& b);
				void transform(matrix4 const& b);
			]]},
			staticMemberFunctions={[[
				void OBJloader::createBox(OBJloader::Mesh& mesh, m_real sizeX, m_real sizeY, m_real sizeZ);
				void OBJloader::createCylinder(OBJloader::Mesh& mesh, m_real radius, m_real height, int ndiv);
			   ]]}
		},
		{
			name='__luna.worker',
			className='LUAwrapper::Worker',
				wrapperCode=[[
					static int __call(lua_State *L)
				{
					lunaStack lua(L);
					LUAwrapper::Worker* self=lua.check<LUAwrapper::Worker>();
					std::string workName;
					lua>>workName;

					TString w(workName.c_str());
					return self->work(w,lua);
				}
			]],
			customFunctionsToRegister={'__call'},
		},
		{
			name='GlobalUI',
			inheritsFrom='LUAwrapper::Worker',
		},
		{
			name='FlLayout',
			inheritsFrom='LUAwrapper::Worker',
			memberFunctions={[[
				void begin()
				FlLayout* layout(int n);
				FlLayout* findLayout(const char* id)
				void create(const char* type, const char* id, const char* title);
				void create(const char* type, const char* id);
				void create(const char* type, const char* id, const char* title, int startSlot, int endSlot, int height);
				void resetToDefault()
				void create(const char* type, const char* id, const char* title, int startSlot, int endSlot);
				void create(const char* type, const char* id, const char* title, int startSlot);
				void newLine(); // 다음줄로 옮긴다. (디폴트 widgetPosition에서는 자동으로 넘어가니 call안해주어도 됨.)
				void embedLayout(FlLayout* childLayout, const char* id, const char* title);
				void setLineSpace(int l);
				void setHorizSpace(int h);
				void setWidgetHeight(int h);
				void setWidgetPos(int startSlot, int endSlot); // guideline 따라 나누어져있는 영역에서 얼만큼 차지할지.
				void setUniformGuidelines(int totalSlot); // 가로로 totalSlot등분한다.
				void updateLayout();
				void resetToDefault()
				void redraw()
				void activate()
				void deactivate()
				int minimumHeight();
				FlLayout::Widget& widgetRaw(int n); @ widget
				int widgetIndex(const char* id);	//!< 버튼 10개를 생성한후 첫번째 버튼의 index를 받아오면, 그 이후의 버튼은 index+1, index+2.등으로 접근 가능하다.
				FlLayout::Widget& findWidget(const char* id);
				void callCallbackFunction(FlLayout::Widget& w);
						 ]]}
		},
		{
			name='FlLayout.Widget',
			wrapperCode=[[
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
				w.menu()->redraw();
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
			static void buttonTooltip(FlLayout::Widget& w, const char* s)
			{
#ifndef NO_GUI				
				w.button()->tooltip(s);
#endif
			}
			static void buttonSetLabel(FlLayout::Widget& w, const char* s)
			{
#ifndef NO_GUI				
				w.button()->copy_label(s);
#endif
			}
			static void redraw(FlLayout::Widget& w)
			{
				w.widget<Fl_Widget>()->redraw();
			}
			static void deactivate(FlLayout::Widget& w)
			{
#ifndef NO_GUI				
				w.widget<Fl_Widget>()->deactivate();
#endif
			}
			static void activate(FlLayout::Widget& w)
			{
#ifndef NO_GUI				
				w.widget<Fl_Widget>()->activate();
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
static void inputType(FlLayout::Widget& w, const char* str)
			{
#ifndef NO_GUI
				if (TString(str)=="FL_MULTILINE_OUTPUT")
				{
					Fl_Input* ip=w.widget<Fl_Input>();
					ip->type(FL_MULTILINE_OUTPUT);
				}
#endif
			}
			]],
			staticMemberFunctions={[[
			static void checkButtonValue(FlLayout::Widget& w, int value)
			static bool checkButtonValue2(FlLayout::Widget& w) @ checkButtonValue
			static void checkButtonValue3(FlLayout::Widget& w, bool value) @ checkButtonValue
			static void menuSize(FlLayout::Widget& w,int nsize)
			static void menuItem(FlLayout::Widget& w,int i, const char* title)
			static void menuItem2(FlLayout::Widget& w,int i, const char* title, const char* shortc) @ menuItem
			static void menuValue(FlLayout::Widget& w, int v)
			static std::string menuText(FlLayout::Widget& w, int v)
			static std::string menuText2(FlLayout::Widget& w) @ menuText
			static int menuValue2(FlLayout::Widget& w) @ menuValue
			static void sliderValue(FlLayout::Widget& w, double v)
			static void sliderStep(FlLayout::Widget& w, double v)
			static void sliderRange(FlLayout::Widget& w, double v1, double v2)
			static double sliderValue2(FlLayout::Widget& w) @ sliderValue
			static void buttonShortcut(FlLayout::Widget& w, const char* s)
			static void buttonTooltip(FlLayout::Widget& w, const char* s)
			static void buttonSetLabel(FlLayout::Widget& w, const char* s)
			static void redraw(FlLayout::Widget& w)
			static void deactivate(FlLayout::Widget& w)
			static void activate(FlLayout::Widget& w)
			static const char* id(FlLayout::Widget& w)
			static int browserSize(FlLayout::Widget& w)
			static bool browserSelected(FlLayout::Widget& w, int i)
			static void browserDeselect(FlLayout::Widget& w)
			static void browserSelect(FlLayout::Widget& w,int i)
			static void browserAdd(FlLayout::Widget& w, const char* name)
			static void browserClear(FlLayout::Widget& w)
			static void inputValue1(FlLayout::Widget& w, const char* text) @ inputValue
			static std::string inputValue2(FlLayout::Widget& w) @ inputValue
			static void inputType(FlLayout::Widget& w, const char* str)
			]]}

		},
		{
			name='OBJloader.Face'
		},
{
	name='Ogre.MovableObject',
memberFunctions={[[
        void setCastShadows(bool enabled) @ ;ifndef=NO_GUI;
]]}
},
{
name='Ogre.Light',
	ifndef='NO_GUI',
			inheritsFrom='Ogre::MovableObject',
	wrapperCode=[[
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
	]],
staticMemberFunctions={[[
			static void setType(Ogre::Light* light, const char* type)
			static void setSpecularColour(Ogre::Light* light, m_real x, m_real y, m_real z)
			static void setDiffuseColour(Ogre::Light* light, m_real x, m_real y, m_real z)
			static void setPosition(Ogre::Light* light, m_real x, m_real y, m_real z)
			static void setDirection(Ogre::Light* light, m_real x, m_real y, m_real z)
				   ]]}

},
		{ 
			name='Ogre.Entity',
	ifndef='NO_GUI',
			inheritsFrom='Ogre::MovableObject',
			wrapperCode=[[
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
			]],
			staticMemberFunctions={[[
			void setNormaliseNormals(Ogre::Entity& e)
			void setMaterialName(Ogre::Entity& e, const char* matName)
						 ]]},
		},
		{
			name='Ogre.Overlay',
			ifndef='NO_GUI',
			memberFunctions={[[
			void setZOrder(ushort zorder);
			ushort getZOrder(void) const;
			void add2D(Ogre::OverlayContainer* cont);
			void show(void);
			void hide(void);
			]]}
		},
		{
			name='Ogre.OverlayElement',
			ifndef='NO_GUI',
			wrapperCode=[[
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
			]],
			staticMemberFunctions={[[
			static void setCaption(Ogre::OverlayElement* p, const char* caption)
			static void setMaterialName(Ogre::OverlayElement* p, const char* c)
			static void setParameter(Ogre::OverlayElement* p, const char* c, const char* d)
			]]}
		},
		{
			name='Ogre.OverlayContainer',
			ifndef='NO_GUI',
			inheritsFrom='Ogre::OverlayElement',
			memberFunctions={[[
			void addChild(Ogre::OverlayElement* elem);
			]]}
		},
{
	name='math.WeightedPointCloudMetric',
	className='WeightedPointCloudMetric',
	ctors={'(vectorn const&)'},
	properties={
	'matrix4 m_transfB @ transfB',
	'matrixn m_transformedB @ transformedB',	
	'bool errorOccurred',
	},
memberFunctions={[[
	m_real CalcDistance(const vectorn& a, const vectorn& b); @ calcDistance
]]}
},
{
	name='math.KovarMetric',
	className='KovarMetric',
	ctors={'()', '(bool)'},
	properties={
	'matrix4 m_transfB @ transfB',
	'matrixn m_transformedB @ transformedB',	
	},
memberFunctions={[[
	m_real CalcDistance(const vectorn& a, const vectorn& b); @ calcDistance
]]}
},
		{ 
			name='Ogre.SceneNode',
			wrapperCode=[[ static void resetToInitialState(Ogre::SceneNode* pNode)
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
			static void translate(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->translate(x, y, z));}
			static void scale(Ogre::SceneNode* pNode, vector3 const& t)
			{OGRE_VOID(pNode->scale(t.x, t.y, t.z));}
			static void scale(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->scale(x, y, z));}

			static void setPosition(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->setPosition(x,y,z));}
			static void setPosition(Ogre::SceneNode* pNode, vector3 const& t)
			{OGRE_VOID(pNode->setPosition(t.x,t.y,t.z));}
			static void setScale(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->setScale(x,y,z));}
			static void setScaleAndPosition(Ogre::SceneNode* pNode, vector3 const& s, vector3 const& t)
			{OGRE_VOID(pNode->setScale(s.x,s.y,s.z);pNode->setPosition(t.x,t.y,t.z));}
			static void setOrientation(Ogre::SceneNode* pNode, m_real w, m_real x, m_real y, m_real z)
			{OGRE_VOID(pNode->setOrientation(w, x,y,z));}
			static void setOrientation(Ogre::SceneNode* pNode, quater const& q)
			{OGRE_VOID(pNode->setOrientation(q.w, q.x,q.y,q.z));}
			]],
			staticMemberFunctions={[[
			static void resetToInitialState(Ogre::SceneNode* pNode)
			static void removeAndDestroyChild(Ogre::SceneNode* pNode, const char* name)
			static Ogre::SceneNode* createChildSceneNode2(Ogre::SceneNode* pNode) @ createChildSceneNode
			static Ogre::SceneNode* createChildSceneNode(Ogre::SceneNode* pNode, const char* name) 
			static void translate(Ogre::SceneNode* pNode, vector3 const& t)
			static void rotate(Ogre::SceneNode* pNode, quater const& t)
			static void translate(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			static void scale(Ogre::SceneNode* pNode, vector3 const& t)
			static void scale(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			static void setPosition(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			static void setPosition(Ogre::SceneNode* pNode, vector3 const& t)
			static void setScale(Ogre::SceneNode* pNode, m_real x, m_real y, m_real z)
			static void setScaleAndPosition(Ogre::SceneNode* pNode, vector3 const& s, vector3 const& t)
			static void setOrientation(Ogre::SceneNode* pNode, m_real w, m_real x, m_real y, m_real z)
			static void setOrientation(Ogre::SceneNode* pNode, quater const& q)
			]]},
			memberFunctions={[[
			void attachObject(Ogre::MovableObject* ); @ ;ifndef=NO_OGRE;
			int numAttachedObjects(); @ ;ifndef=NO_OGRE;
			]]}
	},
		{ 
			name='Ogre.SceneManager',
			decl='namespace Ogre { class Light; }',
			wrapperCode=[[
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
			]],
			staticMemberFunctions={[[
			static Ogre::Entity* createEntity(Ogre::SceneManager* pmgr, const char* id, const char* mesh)
			static void setAmbientLight(Ogre::SceneManager* pmgr, m_real x, m_real y, m_real z)
			static Ogre::SceneNode* getSceneNode(Ogre::SceneManager* pmgr, const char* id)
			static Ogre::Light* createLight(Ogre::SceneManager* pmgr, const char* id)
			static void setSkyBox(Ogre::SceneManager* pmgr, bool enable, const char* materialName)
							  ]]}
		},
		{
			name='Bone',
			wrapperCode=[[

			static bool isChildHeadValid(Bone& bone)   { return bone.m_pChildHead!=NULL;}
			static bool isChildTailValid(Bone& bone)   { return bone.m_pChildTail!=NULL;}
			static bool isSiblingValid(Bone& bone)   { return bone.m_pSibling!=NULL;}

			static Bone* childHead(Bone& bone)	{ return ((Bone*)bone.m_pChildHead);}
			static Bone* childTail(Bone& bone)	{ return ((Bone*)bone.m_pChildTail);}
			static Bone* sibling(Bone& bone)	{ return ((Bone*)bone.m_pSibling);}

			static void getTranslation(Bone& bone, vector3& trans)
			{
				bone.getTranslation(trans);
			}
			static vector3 getTranslation(Bone& bone)
			{
				return bone.getTranslation();
			}
			static vector3 getOffset(Bone& bone)
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
	]],
	read_properties={{'NameId', 'name'}},
			staticMemberFunctions={[[
			static bool isChildHeadValid(Bone& bone) 
			static bool isChildTailValid(Bone& bone)
			static bool isSiblingValid(Bone& bone) 
			static Bone* childHead(Bone& bone)	
			static Bone* childTail(Bone& bone)
			static Bone* sibling(Bone& bone)
			static void getTranslation(Bone& bone, vector3& trans)
			static vector3 getTranslation(Bone& bone)
			static vector3 getOffset(Bone& bone)
			static void getRotation(Bone& bone, quater& q)
			static bool eq(Bone& bone1, Bone& bone2) @ __eq
			static std::string name(Bone& bone)
			static std::string name(Bone& bone) @ __tostring
			]]},
			memberFunctions={[[
			void SetNameId(const char*) @ setName
			transf & _getOffsetTransform() ; @ getOffsetTransform
			transf & _getFrame() const; @ getFrame
			transf & _getLocalFrame() const; @ getLocalFrame
			m_real length() const;
			void getOffset(vector3& offset) const;
			vector3 axis(int ichannel);
			Bone* parent() const	
			Bone* sibling() const
			bool isDescendent(const Bone * parent) const;
			TString const& getRotationalChannels() const;
			TString const& getTranslationalChannels() const;
			void setChannels(const char* translation_axis, const char* rotation_axis);
			int numChannels() const;
			Bone* parent() const	
			int voca() const	
			MotionLoader const& getSkeleton() const
			int treeIndex() const		
			int rotJointIndex() const
			int transJointIndex() const
			]]}
		},
		{
			name='MotionDOFinfo',
			ctors={"()"},
			enums={ 
				{'ROTATE','(int)MotionDOFinfo::ROTATE'}, 
				{'SLIDE', '(int)MotionDOFinfo::SLIDE'},
				{'QUATERNION_W','(int)MotionDOFinfo::QUATERNION_W'}, 
				{'QUATERNION_X','(int)MotionDOFinfo::QUATERNION_X'}, 
				{'QUATERNION_Y','(int)MotionDOFinfo::QUATERNION_Y'}, 
				{'QUATERNION_Z','(int)MotionDOFinfo::QUATERNION_Z'},
			}
			,memberFunctions={
				[[
				MotionLoader & skeleton() const	{return *_sharedinfo->mSkeleton;}
				int numDOF() const; // including quaternion's additional variables.
				int numActualDOF() const; // numDOF()- numSphericalJoint()
				int numBone() const;
				int numDOF(int ibone) const;
				int DOFtype(int ibone, int offset) const;
				int DOFindex(int ibone, int offset) const;
				int sphericalDOFindex(int isphericalJoint) const;
				int numSphericalJoint() const;
				double frameRate() const;
				void setFrameRate(double f);
				void getDOF(Posture const& p, vectorn& dof) const;
				void setDOF(vectorn const& dof, Posture& p) const;
				Posture const& setDOF(vectorn const& dof) const;	//!< non thread-safe
				bool hasTranslation(int iBone) const;
				bool hasQuaternion(int iBone) const;
				bool hasAngles(int iBone) const;
				int startT(int iBone) const;
				int startR(int iBone) const;
				int endR(int iBone) const;
				int startDQ(int iBone) const; 
				int endDQ(int iBone) const;
				int DQtoBone(int DQindex)
				int DOFtoBone(int DOFindex)
				int DOFtoDQ(int DOFindex) 
				int DQtoDOF(int DOFindex)
				void blend(vectorn & out, vectorn const& p1, vectorn const& p2, m_real t) const;
				void blendDelta(vectorn & out, vectorn const& p1, vectorn const& p2, m_real t) const;
				void blendBone(int ibone, vectorn & c, vectorn const& a, vectorn const& b, m_real t) const;
				]]
}
		},
		{
			name='CMotionDOFcontainer',
			className='MotionDOFcontainer',
			decl=[[class MotionDOFcontainer;]],
			ctors={[[
				(MotionDOFinfo const& info, const char* filename);
				(MotionDOFinfo const& info);
				(MotionDOF const& mot);
			]]},
			properties={
				'MotionDOF mot',
				'boolN discontinuity',
				'boolN conL',
				'boolN conR',
			},
			memberFunctions={[[
				void loadMotion(const char* fn);
				void resize(int nframes);
				void concat(MotionDOF const& mot);
				vectornView row(int i)
				int numFrames() const;
				bool isConstraint(int iframe, int con) const;
				void setConstraint(int iframe, int con);
				void setConstraint(int iframe, int con, bool bSet);
				bool isContinuous(int startTime) const;
				bool isValid(int startTime, int endTime) const;
				bool isValid(int startTime) const;
			]]},
		},
		{
			name='InterframeDifferenceC1',
	ctors={'(MotionDOF const& input)', '(m_real)'},
memberFunctions={[[
	void resize(int numFrames);
	int numFrames()	
	void initFromDeltaRep(vectorn const& start_transf, matrixn const& input);
	vectorn exportToDeltaRep(matrixn & output);
	void reconstruct(matrixn& output);	// output can be MotionDOF.
	static vectorn getTransformation(matrixn const& motionDOF, int iframe);
]]},
properties={
	'vector3 startPrevP',
	'vector3 startP',
	'quater startRotY',
	'm_real _frameRate',
	'vector3N dv',
	'vector3N dq',
	'vectorn offset_y',
	'quaterN offset_qy',
	'quaterN offset_q',
},
},
		{
			name='InterframeDifference',
	ctors={'(MotionDOF const& input)', '()'},
properties={
	'vector3 startP',
	'quater startRotY',
	'vector3N dv',
	'vector3N dq',
	'vectorn offset_y',
	'quaterN offset_q',
},
memberFunctions={[[
	void resize(int numFrames);
	int numFrames()
	void initFromDeltaRep(vector3 const& start_transf, matrixn const& input);
	vector3 exportToDeltaRep(matrixn & output);
	void reconstruct(matrixn& output, m_real frameRate);
]]}
		},
		{
			name='MotionDOF',
			inheritsFrom='matrixn',
			ctors={ "(const MotionDOFinfo&)", "(const MotionDOF&)"},
			properties={	"MotionDOFinfo mInfo @ dofInfo"},
			staticMemberFunctions={
				[[
				static transf MotionDOF::rootTransformation(vectorn const& pose);
				static void MotionDOF::setRootTransformation(vectorn & pose, transf const& t);	
				]]
			},

			memberFunctions={
				[[
				void operator=(const MotionDOF& other);
				void operator=(const MotionDOF& other); @ copyFrom
				void operator=(const MotionDOF& other); @ assign 
				matrixnView _matView(); @ matView
				int numFrames()	const			
				int numDOF()	const	
				void resize(int numFrames)	
				void changeLength(int length)
				transf rootTransformation(int i) const;
				void get(Motion& tgtMotion);
				void set(const Motion& srcMotion); 
				MotionDOFview range(int start, int end);	// [start, end)
				MotionDOFview range_c(int first, int last);	// [first, last] (closed interval)
				void samplePose(m_real criticalTime, vectorn& out) const;
				void stitch(MotionDOF const& motA, MotionDOF const& motB);
				void stitchDeltaRep(MotionDOF const& motA, MotionDOF const& motB);
				vectornView row(int i); @ __call
				vector3 convertToDeltaRep();	// see interframeDifference
				void generateID(vector3 const& start_transf, InterframeDifference& out) const;
				void reconstructData(vector3 const & startTransf);
				void reconstructData(vector3 const& startTransf, matrixn& out) const;
				void reconstructData(transf const& startTransf, matrixn& out) const;
				vectornView dv_x() const	
				vectornView dv_z() const	
				vectornView dq_y() const	
				vectornView offset_y() const
	int length() const
				]]
			}
		},
		{ 
			name='MotionDOFview',
inheritsFrom='MotionDOF'
		},
		{
			name='BoneForwardKinematics',
ctors={'(MotionLoader*)'},
wrapperCode=[[
			static transf& localFrame(BoneForwardKinematics& fk, int i){ return fk._local(i);}
			static transf& localFrame(BoneForwardKinematics& fk, Bone& bone){ return fk._local(bone);}
			static transf& globalFrame(BoneForwardKinematics& fk, int i){ return fk._global(i);}
			static transf& globalFrame(BoneForwardKinematics& fk, Bone& bone){return fk._global(bone);}
]],
staticMemberFunctions={[[
			transf& localFrame(BoneForwardKinematics& fk, int i)
			transf& localFrame(BoneForwardKinematics& fk, Bone& bone)
			transf& globalFrame(BoneForwardKinematics& fk, int i)
			transf& globalFrame(BoneForwardKinematics& fk, Bone& bone)
]]},
memberFunctions={[[
	void init();
	void forwardKinematics();
	void inverseKinematics();
	void operator=(BoneForwardKinematics const& other);
	void setPose(const Posture& pose);
	void setPoseDOF(const vectorn& poseDOF);
	void setChain(const Posture& pose, const Bone& bone);
	void getPoseFromGlobal(Posture& pose) const;
	void getPoseDOFfromGlobal(vectorn& poseDOF) const;
	void getPoseFromLocal(Posture& pose) const;
	MotionLoader const& getSkeleton() const		
]]}
		},
		{ 
			name='FrameSensor'
		},
		{
			name='AnimationObject'
		},
		{
			name='Ogre.ObjectList',
			className='ObjectList',
			ctors={'()'},
			memberFunctions={[[
			void clear();
			void setVisible(bool bVisible);
			Ogre::SceneNode* registerEntity(const char* node_name, const char* filename);
			Ogre::SceneNode* registerEntity(const char* node_name, const char* filename, const char* materialName);
			Ogre::SceneNode* registerEntity(const char* node_name, Ogre::Entity* pObject);
			Ogre::SceneNode* registerObject(const char* node_name, Ogre::MovableObject* pObject);
			Ogre::SceneNode* registerObject(const char* node_name, const char* typeName, const char* materialName, matrixn const& data);
			Ogre::SceneNode* registerObject(const char* node_name, const char* typeName, const char* materialName, matrixn const& data, m_real thickness);
			Ogre::SceneNode* registerEntityScheduled(const char* filename, m_real destroyTime);
			Ogre::SceneNode* registerObjectScheduled(Ogre::MovableObject* pObject, m_real destroyTime);
			Ogre::SceneNode* findNode(const char* node_name);
			void erase(const char* node_name);
			void eraseAllScheduled();
			]]},
		},
		{ 

			name='PLDPrimSkin',
			inheritsFrom='AnimationObject',
			read_properties={{"visible", "getVisible"}},
			write_properties={{"visible", "setVisible"}},
			wrapperCode=[[ 
			static void startAnim(PLDPrimSkin& s)
			{
				s.m_pTimer->StartAnim();
			}
			static void setRotation(PLDPrimSkin& s,quater const& q)
			{
				#ifndef NO_OGRE
				s.m_pSceneNode->setOrientation(ToOgre(q));
				#endif
			}
			]],
			staticMemberFunctions={
				[[
				static void startAnim(PLDPrimSkin& s)
				static void setRotation(PLDPrimSkin& s,quater const& q)
				]]
			},
			enums={
				{"BLOB","(int)RE::PLDPRIM_BLOB"},
				{"LINE","(int)RE::PLDPRIM_LINE"},
				{"SKIN","(int)RE::PLDPRIM_SKIN"},
				{"POINT","(int)RE::PLDPRIM_POINT"},
				{"CYLINDER","(int)RE::PLDPRIM_CYLINDER"},
				{"CYLINDER_LOWPOLY","(int)RE::PLDPRIM_CYLINDER_LOWPOLY"},
				{"BOX","(int)RE::PLDPRIM_BOX"}
			},
			memberFunctions={
				[[
				void setPose(const Motion& mot, int iframe)
				void setPose(int iframe)
				void SetPose(const Posture & posture, const MotionLoader& skeleton) @ setPose

				bool GetVisible() const; @ getVisible
				void SetVisible(bool bVisible); @ setVisible
				void ApplyAnim(const Motion& mot); @ applyAnim
				void setThickness(float thick){}
				void scale(double x, double y, double z);
				  void SetTranslation(double x, double y, double z); @ setTranslation
				  void setMaterial(const char* mat)
				]]
			}
		},
		{
			name='PLDPrimVRML',
			inheritsFrom='PLDPrimSkin',
			memberFunctions={[[
			void setPoseDOF(const vectorn& poseDOF);
			void setPose(BoneForwardKinematics const& in);
			void applyAnim(const MotionDOF& motion); @ applyMotionDOF
			]]},
		},
		{
			name='Pose',
			className='Posture',
			ctors={'()', '(const Posture&)'},
			properties={
				'vector3N m_aTranslations; @ translations',
				'quaterN m_aRotations; @ rotations',
				'vector3 m_dv;',
				'quater m_dq;',
				'm_real m_offset_y;',
				'quater m_offset_q;',
				'quater m_rotAxis_y;',
			},
			memberFunctions={[[
	void Init(int numRotJoint, int numTransJoint); @ init
	void identity();
	int numRotJoint() const	
	int numTransJoint() const	
	Posture* clone() const; @ ;adopt=true;
	void Blend(const Posture& a, const Posture& b, m_real t); @ blend	//!< a*(1-t)+b*(t)
	void Blend(const Posture& b, m_real t) @ blend
	void Align(const Posture& other); @ align
	vector3 front();
	void decomposeRot() const;
			]]}
		},
		{ 
			name='FltkRenderer',
			memberFunctions={
				[[
	vector3 screenToWorldXZPlane(float x, float y, float height);
	vector3 screenToWorldXZPlane(float x, float y );
]]}
		},
		{ 
			name='Motion',
			ctors={'(MotionLoader*)','(const Motion&, int,int)'},
			wrapperCode=[[

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
			static void calcInterFrameDifference(Motion& motion)
			{
				motion.CalcInterFrameDifference(0);
			}

			static void translate(Motion& motion, vector3 const& t)
			{
				MotionUtil::translate(motion, t);
			}

			static void smooth(Motion& motion, float kernelRoot, float kernelJoint)
			{
				Motion copy=motion;
				MotionUtil::smooth(motion, copy, kernelRoot, kernelJoint);
			}
			]],
			enums={
				{"IS_DISCONTINUOUS","(int)IS_DISCONTINUOUS"},
			},
			memberFunctions={[[
			int length() const
			void changeLength(int length)	
			void Resize(int size) @ resize
			void empty();
			void setPose(int iframe, const Posture& pose);
			void setSkeleton(int iframe) const;
			MotionLoader& skeleton() const
			int numRotJoints() const	
			int numTransJoints()	const	
			int numFrames() const
			int size() const		
			MotionView range(int start, int end);
			void Init(const Motion& srcMotion, int startFrame, int endFrame); @ init
			void Init(MotionLoader* pSource) @ init
			void InitEmpty(MotionLoader* pSource, int numFrames); @ initEmpty
			void InitEmpty(MotionLoader* pSource, int numFrames, float fFrameTime); @ initEmpty
			void InitEmpty(const Motion& source, int numFrames); @ initEmpty
			void InitSkeleton(MotionLoader* pSource); @ initSkeleton
			bool isConstraint(int fr, int eConstraint) const;
			void setConstraint(int fr, int con, bool bSet);
			void SetIdentifier(const char* id) @ setIdentifier
			void Concat(const Motion* pAdd, int startFrame, int endFrame) @ concat
			float totalTime() const				{ return mInfo.m_fFrameTime*length();}
			int frameRate() const				{ return int(1.f/frameTime()+0.5f);}
			void frameTime(float ftime)		@ setFrameTime
			bool isDiscontinuous(int fr) const;//			{ return m_aDiscontinuity[fr%m_maxCapacity];}
			void setDiscontinuity(int fr, bool value);//	{ m_aDiscontinuity.setValue(fr%m_maxCapacity, value);}
			Posture& pose(int iframe) const;
			void CalcInterFrameDifference(int startFrame ); @ calcInterFrameDifference
			void ReconstructDataByDifference(int startFrame ); @ reconstructFromInterFrameDifference
			void exportMOT(const char* filename) const; @ exportMot
			void samplePose(Posture& pose, m_real criticalTime) const;
			]]},
			staticMemberFunctions={[[
			static void initSkeletonFromFile(Motion& motion, const char* fn)
			static void initFromFile(Motion& motion, const char* fn)
			static void concatFromFile(Motion& motion, const char* fn)
			static void scale(Motion& motion, m_real fScale)
			static void calcInterFrameDifference(Motion& motion)
			static void translate(Motion& motion, vector3 const& t)
			static void smooth(Motion& motion, float kernelRoot, float kernelJoint)
			]]}
		},
		{
			name='MotionView',
			inheritsFrom='Motion'
		},
{
name='FltkMotionWindow',
ifndef='NO_GUI',
memberFunctions={[[
	void addSkin(AnimationObject* pSkin);
	void releaseAllSkin();
	void releaseSkin(AnimationObject* pSkin);
	void detachAllSkin();
	void detachSkin(AnimationObject* pSkin);
	void relaseLastAddedSkins(int nskins);

	int getCurrFrame()				
	int getNumFrame()			
	int getNumSkin()		
	AnimationObject* getSkin(int index)
	void changeCurrFrame(int iframe);
	int playUntil(int iframe);
	int playFrom(int iframe);
]]}
},
{
name='FltkScrollPanel',
ifndef='NO_GUI',
memberFunctions={[[
	void addPanel(const char* filename);
	void addPanel(CImage* pSource);	//!< image will be copyed. You should release pSource
	CImage* createPanel();		//! Create a dynamic panel(you can edit the content of this panel). return empty image. you can create the image by calling CImage::Create(...)
	void addPanel(const boolN& bits, CPixelRGB8 color);
	void addPanel(const intvectorn& indexes);
	void setLabel(const char* label);
	void changeLabel(const char* prevLabel, const char* newLabel);
	const char* selectedPanel()	
	void removeAllPanel();
	void removePanel(CImage* pImage);	//! Remove a dynamic panel.
	void setCutState(const boolN& abCutState) 
	const boolN& cutState()	
	void redraw()
	int currFrame() const
]]}
},
{
ifndef='NO_GUI',
name='Loader',
inheritsFrom='LUAwrapper::Worker',
},
       
		{ 
			name='MotionPanel',
			ifndef='NO_GUI',
			memberFunctions={[[
				FltkMotionWindow* motionWin()	{ return m_motionWin;}
				FltkScrollPanel* scrollPanel()	{ return m_scrollPanel;}
				Loader* loader()				{ return m_loader;}
				Motion& currMotion();
				MotionDOF& currMotionDOF();
				MotionDOFcontainer& currMotionDOFcontainer();
				bool hasMotionDOF();
				bool hasPairMotion();
				void registerMotion(Motion const& mot);
				void registerMotion(MotionDOF const& mot);
				void releaseMotions();
				void redraw();
				int numMotion();
				Motion& motion(int i) const
				MotionDOF& motiondof(int i) const	
			]]}
		},
		{ 
			name='Viewpoint',
			wrapperCode=
			[[
			inline static void update(Viewpoint & view)
			{
				view.CalcHAngle();
				view.CalcVAngle();
				view.CalcDepth();
			}

			inline static void setClipDistances(Viewpoint& view, m_real fnear, m_real ffar)
			{
#ifndef NO_OGRE

				double nn=fnear;
				double ff=ffar;
				RE::renderer().viewport().mCam->setNearClipDistance(Ogre::Real(fnear));
				RE::renderer().viewport().mCam->setFarClipDistance(Ogre::Real(ffar));
#endif
			}

			inline static void setFOVy(Viewpoint& view, m_real degree)
			{
#ifndef NO_OGRE

				RE::renderer().viewport().mCam->setFOVy(Ogre::Radian(Ogre::Degree(degree)));
#endif
			}
			]],
			properties={'vector3 m_vecVPos @ vpos', 'vector3 m_vecVAt @ vat'},
			staticMemberFunctions={
				[[
			void update(Viewpoint & view)
			void setClipDistances(Viewpoint& view, m_real fnear, m_real ffar)
			void setFOVy(Viewpoint& view, m_real degree)
]]
},

			memberFunctionsFromFile={
				source_path..'/viewpoint.h',
				{"setScale", "setScale"},
				{"updateVPosFromVHD", "UpdateVPosFromVHD"},
				{"TurnRight", "TurnRight"},
				{"TurnLeft", "TurnLeft"},
				{"TurnUp", "TurnUp"},
				{"TurnDown", "TurnDown"},
				{"ZoomIn", "ZoomIn"},
				{"ZoomOut", "ZoomOut"},
			}
		},
		{ 
			name='OgreRenderer',
			memberFunctions={
		[[
	void screenshot(bool b);
	void setScreenshotPrefix(const char* prefix);
	void fixedTimeStep(bool b);
	void setCaptureFPS(float fps)
	]]},
		},
		{
			name='MotionUtil.PoseTransfer',
			className='PoseTransfer',
			ctors={
				'(MotionLoader* pSrcSkel, MotionLoader* pTgtSkel)',
				'(MotionLoader* pSrcSkel, MotionLoader* pTgtSkel, const char* convfilename, bool bCurrPoseAsBindPose)',
			},
			memberFunctions={[[
			void setTargetSkeleton(const Posture & srcposture);	
			void setTargetSkeletonBothRotAndTrans(const Posture& srcposture);
			MotionLoader* source() 
			MotionLoader* target()
			]]}
		},
		{ 
			name='MotionLoader',
			ctors={"(const char*)"},
			properties={"Motion m_cPostureIP @ mMotion", 
						"MotionDOFinfo dofInfo"},
			memberFunctions={
				[[
				void setChain(const Posture&, int)const
				void setChain(const Posture&, Bone&)const
				void insertJoint(Bone&, const char*)
			void insertChildBone(Bone& parent, const char* nameId, bool bMoveChildren)
			void insertChildBone(Bone& parent, const char* nameId)
				void setPoseDOF(const vectorn& poseDOF) const
				void getPoseDOF(vectorn& poseDOF) const
	Bone& bone(int index) const;
	Bone& getBoneByTreeIndex(int index)	const;
	Bone& getBoneByRotJointIndex(int iRotJoint)	const;
	Bone& getBoneByTransJointIndex(int iTransJoint)	const;
	Bone& getBoneByVoca(int jointVoca)	const;
	Bone& getBoneByName(const char*) const;
	int getTreeIndexByName(const char* name) const;
	int getTreeIndexByRotJointIndex(int rotjointIndex) const;
	int getTreeIndexByTransJointIndex(int transjointIndex) const;
	int getTreeIndexByVoca(int jointVoca) const;
	int getRotJointIndexByName(const char* nameID) const;
	int getRotJointIndexByTreeIndex(int treeIndex) const;
	int getRotJointIndexByVoca(int jointVoca) const;
	int getTransJointIndexByName(const char* nameID);
	int getTransJointIndexByTreeIndex(int treeIndex) const;
	int getVocaByTreeIndex(int treeIndex) const;
	int getVocaByRotJointIndex(int rotjointIndex) const;
	void _changeVoca(int jointVoca, Bone & bone);
				]],
			},
			wrapperCode=[[
			static void printHierarchy(MotionLoader& skel)
			{
				skel.GetNode(0)->printHierarchy();
			}

			static MotionLoader* getMotionLoader(const char* fn)
			{
				return RE::renderer().m_pMotionManager->GetMotionLoaderPtr(fn);
			}
			static MotionLoader* _create(const char* filename)
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
				else
				{
					l=new MotionLoader(filename);
				}
				return l;
			}
			static void _append(MotionLoader* l, const char* motFile)
			{
				Motion& mot=l->m_cPostureIP;

				if(mot.numFrames()==0)
					l->loadAnimation(mot, motFile);
				else
					RE::motion::concatFromFile(mot, motFile);
			}
			static void loadAnimation(MotionLoader& skel, Motion& mot, const char* fn)
			{
				RE::motion::loadAnimation(skel, mot, fn);
			}
			]],
			staticMemberFunctions={
				[[
				static void loadAnimation(MotionLoader& skel, Motion& mot, const char* fn)
				static MotionLoader* _create(const char* filename) @ ;adopt=true;
				static void _append(MotionLoader* l, const char* motFile)
				static void printHierarchy(MotionLoader& skel)
				static MotionLoader* getMotionLoader(const char* fn)
				]]},
			memberFunctionsFromFile={
				source_path..'/MotionLoader.h',
				{"fkSolver", "fkSolver"},
				{"readJointIndex", "readJointIndex"},
				{"numRotJoint", "numRotJoint"},
				{"numTransJoint", "numTransJoint"},
				{"numBone", "numBone"},
				{"setCurPoseAsInitialPose", "setCurPoseAsInitialPose"},
				{"bone", "bone"},
				{"setPose", "setPose"},
				{"getTreeIndexByName", "getTreeIndexByName"},
				{"getBoneByTreeIndex", "getBoneByTreeIndex"},
				{"getBoneByRotJointIndex", "getBoneByRotJointIndex"},
				{"getBoneByVoca", "getBoneByVoca"},
				{"getBoneByName", "getBoneByName"},
				{"removeAllRedundantBones", "removeAllRedundantBones"},
				{"getTreeIndexByRotJointIndex", "getTreeIndexByRotJointIndex"},
				{"getTreeIndexByTransJointIndex", "getTreeIndexByTransJointIndex"},
				{"getTreeIndexByVoca", "getTreeIndexByVoca"},
				{"getPose", "getPose"},
				{"scale", "Scale"},
				{"scale", "scale"},
				{"insertSiteBones", "insertSiteBones"},
				{"updateBone", "UpdateBone"},
				{"updateInitialBone", "UpdateInitialBone"},
				{"_changeVoca", "_changeVoca"},
			},
			enums={
				{"HIPS", "(int)MotionLoader::HIPS"},
				{"LEFTHIP", "(int)MotionLoader::LEFTHIP"},
				{"LEFTKNEE", "(int)MotionLoader::LEFTKNEE"},
				{"LEFTANKLE", "(int)MotionLoader::LEFTANKLE"},
				{"LEFTTOES", "(int)MotionLoader::LEFTTOES"},
				{"RIGHTHIP", "(int)MotionLoader::RIGHTHIP"},
				{"RIGHTKNEE", "(int)MotionLoader::RIGHTKNEE"},
				{"RIGHTANKLE", "(int)MotionLoader::RIGHTANKLE"},
				{"RIGHTTOES", "(int)MotionLoader::RIGHTTOES"},
				{"CHEST", "(int)MotionLoader::CHEST"},
				{"CHEST2", "(int)MotionLoader::CHEST2"},
				{"LEFTCOLLAR", "(int)MotionLoader::LEFTCOLLAR"},
				{"LEFTSHOULDER", "(int)MotionLoader::LEFTSHOULDER"},
				{"LEFTELBOW", "(int)MotionLoader::LEFTELBOW"},
				{"LEFTWRIST", "(int)MotionLoader::LEFTWRIST"},
				{"RIGHTCOLLAR", "(int)MotionLoader::RIGHTCOLLAR"},
				{"RIGHTSHOULDER", "(int)MotionLoader::RIGHTSHOULDER"},
				{"RIGHTELBOW", "(int)MotionLoader::RIGHTELBOW"},
				{"RIGHTWRIST", "(int)MotionLoader::RIGHTWRIST"},
				{"NECK", "(int)MotionLoader::NECK"},
				{"HEAD", "(int)MotionLoader::HEAD"},
			}
		},
		{
			name='MotionUtil.Effector',
			ctors={'()'},
			properties={'Bone* bone', 'vector3 localpos'},
			wrapperCode=[[
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
			]],
			staticMemberFunctions={[[
			static void init(MotionUtil::Effector& e, Bone* bone, vector3 const& l)
			static void initCOM(MotionUtil::Effector& e, vector3 const& l)
			]]},
		},
		{
			name='MotionUtil.Effectors',
			className='std::vector<MotionUtil::Effector>',
			ctors={'()'},
			memberFunctions={[[

									 void resize(int)
									 MotionUtil::Effector& operator[](int i) @ at
									 MotionUtil::Effector& operator[](int i) @ __call
						 ]]}
		},
{
	name='MotionUtil.FullbodyIK',
	memberFunctions={[[
			void IKsolve(Posture& , vector3N const& )
			void IKsolve(Posture const&, Posture&, vector3N const& )
				 ]]},
},
{
	name='MotionUtil.FullbodyIK_MotionDOF',
	memberFunctions={[[
			void IKsolve(vectorn const& , vectorn& , vector3N const& )
			void IKsolve(vectorn& , vector3N const& )
]]},
},
			{
				name='MainLib.VRMLTransform',
				className='VRMLTransform',
				inheritsFrom='Bone',
				wrapperCode=[[
				static std::string HRPjointName(VRMLTransform& t, int i)
				{
					return std::string(t.HRPjointName(i).ptr());
				}


				]],
				enums={
					{"FREE","HRP_JOINT::FREE"},
					{"BALL","HRP_JOINT::BALL"},
					{"ROTATE","HRP_JOINT::ROTATE"},
					{"FIXED","HRP_JOINT::FIXED"},
					{"GENERAL","HRP_JOINT::GENERAL"},
					{"SLIDE","HRP_JOINT::SLIDE"}
				},
				staticMemberFunctions={[[
				static std::string HRPjointName(VRMLTransform& t, int i)
				]]},
				memberFunctions={[[
				void translateMesh( vector3 const& trans);
				void translateBone(vector3 const& trans);
				void transformMesh(matrix4 const& m);
				void scaleMesh( vector3 const& scale);
				void scaleMass( m_real scalef); 
				void initBones();
				void copyFrom(VRMLTransform const& bone);	
				bool hasShape() const 
				OBJloader::Mesh& getMesh() const 
				int numHRPjoints() const;
				int HRPjointIndex(int i) const;
				int DOFindex(int i) const;
				TString HRPjointName(int i) const;
				int HRPjointType(int i) const;
				TString HRPjointAxis(int i) const;
				int lastHRPjointIndex() const	
				vector3 localCOM() const;
				void setLocalCOM(vector3 const& com);
				double mass();
				vector3 inertia() const;
				void setInertia(double ix, double iy, double iz);
				void jointToBody(vector3& lposInOut) const;
				void bodyToJoint(vector3& lposInOut) const;
				]] },
			},
							{
								name='VRMLloader',
								inheritsFrom='MotionLoader',
								wrapperCode=[[
								inline static const char* name(VRMLloader& l)
								{
									return l.name;
								}
								inline static VRMLTransform* VRMLloader_upcast(Bone& bone)
								{
									return dynamic_cast<VRMLTransform*>(&bone);
								}
								static VRMLTransform* upcast(Bone& bone)
								{
									return dynamic_cast<VRMLTransform*>(&bone);
								}
								static VRMLloader* upcast(MotionLoader* skel)
								{
									return dynamic_cast<VRMLloader*>(skel);
								}
								]]
								,
								ctors={"(const char*)"},
								staticMemberFunctions={[[
								VRMLTransform* upcast(Bone& bone)
								VRMLloader* upcast(MotionLoader* skel)
								void VRMLloader::projectAngles(vectorn & temp1); @ projectAngles
								const char* name(VRMLloader& l)
								]]},
								memberFunctions={
								--void setTotalMass( m_real totalMass); 
									[[
								void printDebugInfo(); 
								void changeTotalMass( m_real totalMass); 
									VRMLTransform& VRMLbone(int treeIndex) const;
									void insertChildJoint(Bone& parent, const char* tchannels, const char* rchannels, const char* nameId, bool bMoveChildren);
									void _updateMeshEntity();
									vector3 calcCOM() const;
									void calcZMP(const MotionDOF& motion, matrixn & aZMP, double kernelSize);
									void exportVRML(const char* filename); @ export
									int numHRPjoints()
									]]
								},
							},
									{
										name='VRMLloaderView',
										inheritsFrom='VRMLloader',
										ctors={'(VRMLloader const& source, Bone& newRootBone, vector3 const& localPos)'},
										properties={
											'Bone* _newRootBone',
											'Bone* _srcRootTransf',
											'vector3 _srcRootOffset',
										},
										memberFunctions={[[
										VRMLloader const & getSourceSkel() 
										void convertSourcePose(vectorn const& srcPose, vectorn& pose) const;
										void convertPose(vectorn const& pose, vectorn& srcPose) const;
										void convertSourceDOFexceptRoot(vectorn const& srcPose, vectorn& pose) const;
										void convertDOFexceptRoot(vectorn const& pose, vectorn& srcPose) const;
										void convertSourceDQexceptRoot(vectorn const& src_dq, vectorn& dq) const;
										void convertDQexceptRoot(vectorn const& dq, vectorn& src_dq) const;
										]]}
									},

	},
	modules={
		{
			namespace='MotionUtil',
			decl=[[
			namespace MotionUtil{
				void exportVRML(Motion const& mot, const char* filename, int start, int end);
				void exportBVH(Motion const& mot, const char* filename, int start, int end);
			}
			]],
			functions={[[
			void MotionUtil::exportVRML(Motion const& mot, const char* filename, int start, int end)
			void MotionUtil::exportBVH(Motion const& mot, const char* filename);
			void MotionUtil::exportBVH(Motion const& mot, const char* filename, int start);
			void MotionUtil::exportBVH(Motion const& mot, const char* filename, int start, int end);
			]]}
		},
		{
			namespace='util',
			functions={[[
				void Msg::msgBox(const char*) @ msgBox
			]]}
		},
		{
			namespace='Ogre',
			ifndef='NO_GUI',
			functions={[[
			Ogre::OverlayContainer* Ogre::createContainer(int x, int y, int w, int h, const char* name) ;
			Ogre::OverlayElement* createTextArea_(const char* name, double width, double height, double top, double left, int fontSize, const char* caption, bool show); @ createTextArea
			Ogre::Overlay* createOverlay_(const char* name); @ createOverlay
			void destroyOverlay_(const char* name); @ destroyOverlay
			void destroyOverlayElement_(const char* name); @ destroyOverlayElement
			void destroyAllOverlayElements_(); @ destroyAllOverlayElements
			]]}
		},
		{
			namespace='Fltk',
			wrapperCode=[[
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

			]],
			functions={[[
			static std::string chooseFile(const char* msg, const char* path, const char* mask, bool bCreate)
			static bool ask(const char* msg)
			]]}
		},
		{
			namespace='sop',
			functions={[[
			m_real sop::map(m_real t, m_real min, m_real max, m_real v1, m_real v2)
			m_real sop::clampMap(m_real t, m_real min, m_real max, m_real v1, m_real v2)
			]]}
		},
		{
			namespace='MotionUtil',
			functions={[[
			MotionUtil::FullbodyIK_MotionDOF* createFullbodyIk_MotionDOF_MultiTarget(MotionDOFinfo const& info, std::vector<MotionUtil::Effector>& effectors);
			MotionUtil::FullbodyIK_MotionDOF* createFullbodyIkDOF_limbIK(MotionDOFinfo const& info, std::vector<MotionUtil::Effector>& effectors, Bone const& left_knee, Bone const& right_knee);
			MotionUtil::FullbodyIK_MotionDOF* createFullbodyIkDOF_limbIK_straight(MotionDOFinfo const& info, std::vector<MotionUtil::Effector>& effectors, Bone const& left_knee, Bone const& right_knee);
			void setLimbIKParam_straight(MotionUtil::FullbodyIK_MotionDOF* ik, bool bStraight);
			void MotionUtil::exportVRMLforRobotSimulation(Motion const& mot, const char* filename, const char* robotname);
			]]}
		},
		{
			namespace='RE',
			wrapperCode=[[
			inline static Ogre::Entity* RE_createPlane2(const char* id, m_real width, m_real height, int xsegment, int ysegment)
			{
				return RE::createPlane(id,width,height,xsegment,ysegment,1,1);
			}
			]],
			functions=
			{
				[[
				Ogre::SceneManager* RE::ogreSceneManager();
				void RE_outputRaw(const char* key, const char* output, int i); @ _output
				void RE_dumpOutput(TStrings& output, int i); @ dumpOutput
				void RE_outputEraseAll(int i); @outputEraseAll
				void RE::outputState(bool bOutput);
				MotionLoader* RE::motionLoader(const char* name);
				Ogre::SceneNode* RE::ogreRootSceneNode();
				Ogre::SceneNode* RE::createChildSceneNode(Ogre::SceneNode* parent, const char* child_name);
				FrameSensor* RE::createFrameSensor();
				TString RE::generateUniqueName();
				static void RE_::remove(PLDPrimSkin* p)
				Ogre::SceneNode* RE::createEntity(const char* id, const char* filename)
				void RE::removeEntity(Ogre::SceneNode*)
				void RE::setMaterialName(Ogre::SceneNode* pNode, const char* mat);
				void RE::moveEntity(Ogre::SceneNode*, quater const&, vector3 const&)
				Ogre::Entity* RE::createPlane(const char* id, m_real width, m_real height, int xsegment, int ysegment, int texSegx, int texSegy)
				Ogre::Entity* RE_createPlane2(const char* id, m_real width, m_real height, int xsegment, int ysegment)
				Ogre::Entity* RE::createTerrain(const char* id, const char* filename, int imageSizeX, int imageSizeY, m_real sizeX, m_real sizeZ, m_real heightMax, int ntexSegX, int ntexSegZ);
				void RE_::setBackgroundColour(m_real r, m_real g, m_real b)
				static Viewpoint* RE_::getViewpoint() @ viewpoint
				MotionPanel& RE::motionPanel(); @;ifndef=NO_GUI;
				bool RE::rendererValid();
				bool RE::motionPanelValid();
				OgreRenderer& RE::renderer();
				FltkRenderer& RE::FltkRenderer();
				void RE_::renderOneFrame(bool check)
				PLDPrimVRML* RE::createVRMLskin(VRMLloader*pTgtSkel, bool bDrawSkeleton) @ ;adopt=true; 
				]],
				{"PLDPrimSkin* RE::createSkin(const Motion&)", adopt=true},
				{"PLDPrimSkin* RE::createSkin(const MotionLoader&)", adopt=true},
				{"PLDPrimSkin* RE::createSkin(const Motion&, RE::PLDPrimSkinType type)", adopt=true},
				{"PLDPrimSkin* RE::createSkin(const MotionLoader&, RE::PLDPrimSkinType type)", adopt=true},
			}
		}
	}
}


	function generateMainLib() 
-- declaration
write([[
class CMAwrap;
namespace MotionUtil
{
class COM_IKsolver;
class LimbIKsolver;
}
namespace Ogre
{
	class MovableObject;
	class Entity;
	class Overlay;
	class OverlayElement;
	class OverlayContainer;
	class SceneNode;
	class SceneManager;
}
namespace OBJloader
{
class Mesh;
class MeshToEntity;
class Face;
}
namespace MotionUtil
{
class Effector;
class FullbodyIK;
class FullbodyIK_MotionDOF;
}
class GlobalUI;
class Bone;
class PLDPrimSkin;
class MotionDOFinfo;
class InterframeDifference;
class InterframeDifferenceC1;
class Motion;
class MotionDOF;
class MotionDOFview;
class BoneForwardKinematics;
class FrameSensor;
class AnimationObject;
class Posture;
class FltkRenderer;
class MotionPanel;
class MotionView;
class OgreRenderer;
class PoseTransfer;
class MotionLoader;
class QuadraticFunction;
class QuadraticFunctionHardCon;
class FltkMotionWindow;
class FltkScrollPanel;
class Loader;
class ObjectList;
class WeightedPointCloudMetric;
class KovarMetric;
class VRMLloader;
class VRMLloaderView;
class VRMLTransform;
class FlLayout;
class Viewpoint;
class FlChoiceWins;
class PLDPrimVRML;
]])
writeHeader(bindTargetMainLib)
flushWritten(	source_path..'/generated/luna_mainlib.h')
-- write function can be used liberally.
write(
[[
#include "stdafx.h"
#include "../MainLib/OgreFltk/MotionPanel.h"
#include "../MainLib/OgreFltk/FltkScrollPanel.h"
#include "../BaseLib/motion/MotionRetarget.h"
#include "../BaseLib/motion/MotionUtil.h"
#include "../BaseLib/motion/VRMLexporter.h"
#include "../BaseLib/math/Operator.h"
#include "../BaseLib/math/Metric.h"
#include "../BaseLib/motion/viewpoint.h"
#include "../MainLib/OgreFltk/FlLayout.h"
#include "../MainLib/OgreFltk/Mesh.h"
#include "../MainLib/OgreFltk/objectList.h"
#include "../MainLib/OgreFltk/MotionManager.h"
#include "../MainLib/OgreFltk/renderer.h"
#include "../MainLib/Ogre/intersectionTest.h"
#include "../BaseLib/motion/FullbodyIK_MotionDOF.h"
#include "../MainLib/OgreFltk/VRMLloader.h"
#include "../MainLib/OgreFltk/VRMLloaderView.h"
#include "../MainLib/OgreFltk/GlobalUI.h"
#include "../MainLib/OgreFltk/FltkRenderer.h"
#include "../MainLib/OgreFltk/FlChoice.h"
#include "../MainLib/OgreFltk/FlLayout.h"
#include "../MainLib/WrapperLua/LUAwrapper.h"
#include "../MainLib/WrapperLua/LUAwrapper.h"
#include "../MainLib/OgreFltk/framemoveobject.h"
#include "../MainLib/OgreFltk/timesensor.h"
#include "../MainLib/OgreFltk/AnimationObject.h"
#include "../MainLib/OgreFltk/FltkRenderer.h"
#include "../MainLib/OgreFltk/FltkAddon.h"
#include "../MainLib/OgreFltk/MotionPanel.h"
#include "../BaseLib/motion/MotionWrap.h"
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
void FastCapture_convert(const char* filename);
int FlGenShortcut(const char* s);

#ifndef NO_OGRE
#define BEGIN_OGRE_CHECK try {
#define END_OGRE_CHECK	} catch ( Ogre::Exception& e ) {Msg::msgBox(e.getFullDescription().c_str());}

#include "OgreOverlayContainer.h"
#include "OgreOverlayElement.h"

namespace Ogre
{

	Ogre::OverlayContainer* createContainer(int x, int y, int w, int h, const char* name) ;
	Ogre::OverlayElement* createTextArea(const String& name, Ogre::Real width, Ogre::Real height, Ogre::Real top, Ogre::Real left, uint fontSize, const String& caption, bool show) ;
}

Ogre::Overlay* createOverlay_(const char* name);
void destroyOverlay_(const char* name);
void destroyOverlayElement_(const char* name);
void destroyAllOverlayElements_();
Ogre::OverlayElement* createTextArea_(const char* name, double width, double height, double top, double left, int fontSize, const char* caption, bool show);
#endif
#include "../MainLib/WrapperLua/mainliblua_wrap.h"
#ifdef _MSC_VER
typedef unsigned short ushort;
#endif

		]]
		)
		writeIncludeBlock(true)
		write([[
					  class LMat;
					  class LMatView;
					  class LVec;
					  class LVecView;
		  ]])
		write('#include "luna_baselib.h"')
		write('#include "luna_mainlib.h"')
		write('#include "../BaseLib/motion/ASFLoader.h"')
		write('#include "../BaseLib/motion/BVHLoader.h"')
		writeDefinitions(bindTargetMainLib, 'Register_mainlib') -- input bindTarget can be non-overlapping subset of entire bindTarget 
		flushWritten(source_path..'/generated/luna_mainlib.cpp') -- write to cpp file only when there exist modifications -> no-recompile.
	end
