
gen_lua.enum_types[#gen_lua.enum_types+1]='OpenHRP::DynamicsSimulator::IntegrateMethod'
gen_lua.enum_types[#gen_lua.enum_types+1]='OpenHRP::DynamicsSimulator::LinkDataType'

bindTargetPhysics={
	namespaces={
		MainLib={
			'VRMLloader','VRMLloaderView'
		}
	},
	classes={
		{
			name='Physics.MRDplot',
			className='MRDplot',
			properties={[[
			TStrings names;
			TStrings units;
			matrixn data;
			]]},
			ctors={'()'},
			memberFunctions={[[
			void initMRD(int n_channels, int numpoints, m_real frequency);
			int numPoints() const;
			int numChannels() const;
			void setAllUnits(const char* unitname);
			void load(const char* filename);
			void save(const char* filename) const;
			void addPoint(const vectorn& vv);
			void addChannel(const vectorn& vv, const char* name, const char* unit);
			]]}
			
		},
		{
			name='Physics.ContactBasis',
			className='OpenHRP::DynamicsSimulator_gmbs::ContactBasis',
			properties={'int ibody', 'int ibone', 'vector3 globalpos', 'vector3 relvel', 'vector3 normal', 
			'vector3N frictionNormal', 'int globalIndex', 'int globalFrictionIndex'},
		},
		{
			name='Physics.Vec_ContactBasis',
			className='std::vector<OpenHRP::DynamicsSimulator_gmbs::ContactBasis>',
			ctors={'()'},
			memberFunctions={[[
									 int size();
									 OpenHRP::DynamicsSimulator_gmbs::ContactBasis& operator[](int i); @ __call
						 ]]}
			

		},
		{
			name='Physics.ContactForce',
			className='OpenHRP::DynamicsSimulator::ContactForce',
			properties={
				'int chara',
				'VRMLTransform* bone',
				'vector3 f',
				'vector3 p',
				'vector3 tau',	
			}
		},
		{
			name='HessianQuadratic',
			ctors={'(int)'},
			properties={'matrixn H', 'matrixn R'},
			memberFunctions={[[
			void addSquared(intvectorn const& , vectorn const& );
			]]},
			staticMemberFunctions={[[
			double solve_quadprog( HessianQuadratic & problem, const matrixn & CE, const vectorn & ce0, const matrixn & CI, const vectorn & ci0, vectorn & x) @ solveQuadprog
			]]}
		},
		{
			name='CartPoleBallCpp',
			className='std::vector<float>', -- not yet wrapped.
		},
		{ 
			name='Physics.Vec_CFinfo',
			className='std::vector<OpenHRP::DynamicsSimulator::ContactForce>',
			ctors={'()'},
			memberFunctions={[[
			int size();
			]]},
			wrapperCode=[[
			static OpenHRP::DynamicsSimulator_gmbs::ContactBasis& __call2(std::vector<OpenHRP::DynamicsSimulator_gmbs::ContactBasis> const& in, int index)
			{
				return (OpenHRP::DynamicsSimulator_gmbs::ContactBasis&)(in[index]);
			}
			static OpenHRP::DynamicsSimulator::ContactForce & __call(std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in, int index)
			{
				return (OpenHRP::DynamicsSimulator::ContactForce &)(in[index]);
			}

			static void assign(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in) 
			{
				out.resize(in.size());
				for(int i=0; i<in.size(); i++){ out[i]=in[i];}
			}

			static void normalize(OpenHRP::DynamicsSimulator::ContactForce & cf2,
			OpenHRP::DynamicsSimulator::ContactForce const& cf,
			OpenHRP::DynamicsSimulator & sim)
			{
				Bone* b= cf.bone;
				vector3 gf=sim.getWorldState(cf.chara)._global(*b).toGlobalDir(cf.f);
				vector3 gp=sim.getWorldState(cf.chara)._global(*b).toGlobalPos(cf.p);
				vector3 gtau=gp.cross(gf)+sim.getWorldState(cf.chara)._global(*b).toGlobalDir(cf.tau);

				cf2.bone=cf.bone;
				cf2.chara=cf.chara;				
				cf2.f=sim.getWorldState(cf.chara)._global(*b).toLocalDir(gf);
				cf2.p=sim.getWorldState(cf.chara)._global(*b).toLocalPos(vector3(0,0,0));
				cf2.tau=sim.getWorldState(cf.chara)._global(*b).toLocalDir(gtau);
			}

			static void scale(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, 
			double s)
			{
				// assumes that cf has been normalized.
				for (int i=0; i<out.size(); i++){
					out[i].f*=s;
					out[i].tau*=s;
				}				
			}

			static void compaction(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in1, OpenHRP::DynamicsSimulator & sim)
			{
				out.reserve(in1.size());
				out.resize(0);

				for(int i=0; i<in1.size(); i++){

					if (in1[i].chara==0){// ignore chara2 assuming it's static object.
						if(out.size()==0 || out.back().bone!=in1[i].bone){
							OpenHRP::DynamicsSimulator::ContactForce cf;
							normalize(cf, in1[i], sim);
							out.push_back(cf);
						}
					else {
						OpenHRP::DynamicsSimulator::ContactForce cf;
						normalize(cf, in1[i], sim);

						OpenHRP::DynamicsSimulator::ContactForce& cf2=out.back();
						cf2.f+=cf.f;
						cf2.tau+=cf.tau;
					}
					}
				}
			}

			static void merge(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, 
			std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in1,
			std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in2)
			{
				// assumes that both in1 and in2 are normalized
				intvectorn indexes;

				for (int i=0; i<in1.size(); i++){
					Msg::verify(indexes.findFirstIndex(in1[i].bone->treeIndex())==-1, "index==-1");
					indexes.pushBack(in1[i].bone->treeIndex());
				}
				for (int i=0; i<in2.size(); i++){
					int idx=in2[i].bone->treeIndex();
					if(indexes.findFirstIndex(idx)==-1)
						indexes.pushBack(idx);
					}

					out.resize(indexes.size());
					for(int i=0; i<indexes.size(); i++){
						out[i].f.setValue(0,0,0);
						out[i].tau.setValue(0,0,0);
					}

					for (int i=0; i<in1.size(); i++){
						int idx=indexes.findFirstIndex(in1[i].bone->treeIndex());
						Msg::verify(idx!=-1, "idx ==-1");
						out[i].bone=in1[i].bone;
						out[i].chara=in1[i].chara;
						out[i].p=in1[i].p;
						out[i].f+=in1[i].f;
						out[i].tau+=in1[i].tau;
					}
					for (int i=0; i<in2.size(); i++){
						int idx=indexes.findFirstIndex(in2[i].bone->treeIndex());
						out[i].bone=in2[i].bone;
						out[i].chara=in2[i].chara;
						out[i].p=in2[i].p;
						out[i].f+=in2[i].f;
						out[i].tau+=in2[i].tau;
					}



				}

				static void interpolate(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, 					
				m_real t,
				std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in1,
				std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in2,
				OpenHRP::DynamicsSimulator & sim)
				{
					std::vector<OpenHRP::DynamicsSimulator::ContactForce> t1, t2;

					compaction(t1, in1, sim);
					scale(t1, 1-t);

					compaction(t2, in2, sim);
					scale(t2, t);

					printf("here\n");
					merge(out, t1, t2);
				}
				]]
				,staticMemberFunctions={[[

				static OpenHRP::DynamicsSimulator_gmbs::ContactBasis& __call2(std::vector<OpenHRP::DynamicsSimulator_gmbs::ContactBasis>const& in, int index)
				static OpenHRP::DynamicsSimulator::ContactForce & __call(std::vector<OpenHRP::DynamicsSimulator::ContactForce>const& in, int index)
				static void assign(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in)
				static void normalize(OpenHRP::DynamicsSimulator::ContactForce & cf2, OpenHRP::DynamicsSimulator::ContactForce const& cf, OpenHRP::DynamicsSimulator & sim)
				static void scale(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, double s)
				static void compaction(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in1, OpenHRP::DynamicsSimulator & sim)
				static void merge(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in1, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in2)
				static void interpolate(std::vector<OpenHRP::DynamicsSimulator::ContactForce> & out, m_real t, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in1, std::vector<OpenHRP::DynamicsSimulator::ContactForce> const& in2, OpenHRP::DynamicsSimulator & sim)
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


				static void translateMesh(VRMLTransform* bone, vector3 trans)
				{
					matrix4 m;
					m.setTranslation(trans, false);
					bone->mShape->mesh.transform(m);
					bone->mSegment->centerOfMass+=trans;
				}

				static void translateBone(VRMLTransform* bone, vector3 trans)
				{
					bone->mJoint->translation+=trans;
					bone->initBones();
				}

				// m: with respect to global coordinate.
				static void transformMesh(VRMLTransform* bone, matrix4 m)
				{
					m.rightMult(matrix4(bone->getFrame()));
					m.leftMult(matrix4(bone->getFrame().inverse()));
					bone->mShape->mesh.transform(m);
					bone->mSegment->centerOfMass.leftMult(m);

				}


				static void scaleMesh(VRMLTransform& bone, vector3 scale)
				{
					if(bone.mSegment) {
						for(int i=0; i<3; i++){
							for(int j=0; j<3; j++){
								bone.mSegment->momentsOfInertia.m[i][j]*=scale[i]*scale[j];
							}
						}
						matrix4 m;
						m.setScaling(scale.x, scale.y, scale.z);
						bone.mShape->mesh.transform(m);
					}
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
				static void translateMesh(VRMLTransform* bone, vector3 trans)
				static void translateBone(VRMLTransform* bone, vector3 trans)
				static void transformMesh(VRMLTransform* bone, matrix4 m)
				static void scaleMesh(VRMLTransform& bone, vector3 scale)
				]]},
				memberFunctions={[[
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
				vector3 localCOM();
				double mass();
				vector3 inertia();
				void jointToBody(vector3& lposInOut) const;
				void bodyToJoint(vector3& lposInOut) const;
				]] },
			},
						{
							name='Physics.DynamicsSimulator',
							className='OpenHRP::DynamicsSimulator',
							wrapperCode=[[

							static void setParameter2(const char* _what, bool value)
							{
								TString what(_what);

								if(what=="usePenaltyMethod")
									OpenHRP::globals::usePenaltyMethod=value;
								else
									Msg::error("unknown parameter %s", _what);
								}

								static void setParameter(const char* _what, double value)
								{
									TString what(_what);

									Msg::error("unknown parameter %s", _what);
								}

								static int setSimulatorParam(lua_State *L)
								{/*OpenHRP::DynamicsSimulator&s, const char* t, luabind::object const& ll)
								int count=LUAwrapper::arraySize(ll);
								vectorn l;
								l.setSize(count);
								for(int i=0; i<count; i++)
									l[i]=luabind::object_cast<double>(ll[i+1]);	// lua indexing starts from 1.

									s.setSimulatorParam(t, l);
									*/
									return 0;
								}
								static vector3 calcCOM(OpenHRP::DynamicsSimulator&s, int ichara)
								{
									double totalMass;
									return s.calculateCOM(ichara,totalMass);
								}
								static vector3 calcCOMvel(OpenHRP::DynamicsSimulator&s, int ichara)
								{
									double totalMass;
									return s.calculateCOMvel(ichara,totalMass);
								}
								]],
								staticMemberFunctions={[[
								static void setParameter2(const char* _what, bool value) @ setParameter
								static void setParameter(const char* _what, double value)
								static vector3 calcCOM(OpenHRP::DynamicsSimulator&s, int ichara) @ calculateCOM
								static vector3 calcCOMvel(OpenHRP::DynamicsSimulator&s, int ichara) @ calculateCOMvel
								]]},
								memberFunctions={[[	
								void drawDebugInformation() 
								void registerCharacter(VRMLloader*l);
								void createObstacle(OBJloader::Mesh const& mesh);
								void registerCollisionCheckPair( const char* char1, const char* name1, const char* char2, const char* name2, vectorn const& param); 
								void init( double timeStep, OpenHRP::DynamicsSimulator::IntegrateMethod integrateOpt)
								void setTimestep(double timeStep)
								void setGVector(const vector3& wdata);
								void initSimulation();
								void getWorldPosition(int ichara, VRMLTransform* b, vector3 const& localpos, vector3& globalpos) const;
								vector3 getWorldPosition(int ichara, VRMLTransform* b, vector3 const& localpos) const;
								vector3 getWorldVelocity(int ichara,VRMLTransform* b, vector3 const& localpos) const;
								vector3 getWorldAcceleration(int ichara,VRMLTransform* b, vector3 const& localpos) const;
								vector3 getWorldAngVel(int ichara, VRMLTransform* b) const;
								vector3 getWorldAngAcc(int ichara, VRMLTransform* b) const;
								BoneForwardKinematics& getWorldState(int ichara) ;	
								VRMLloader & skeleton(int ichara)
								void setWorldState(int ichara);		
								void calcJacobian(int ichar, int ibone, matrixn& jacobian)
								void calcDotJacobian(int ichar, int ibone, matrixn& dotjacobian)
								void setLinkData(int i, OpenHRP::DynamicsSimulator::LinkDataType t, vectorn const& in);
								void getLinkData(int i, OpenHRP::DynamicsSimulator::LinkDataType t, vectorn& out);	
								bool stepSimulation();
								double currentTime();
								vector3 calculateZMP(int ichara);
								void registerContactQueryBone(int contactQueryIndex, VRMLTransform* bone);
								bool queryContact(int index);
								vectorn queryContacts();
								vectorn queryContactDepths();
								std::vector<OpenHRP::DynamicsSimulator::ContactForce> & queryContactAll();
								]]},
								enums={
									{"EULER","(int)OpenHRP::DynamicsSimulator::EULER"},
									{"RUNGE_KUTTA","(int)OpenHRP::DynamicsSimulator::RUNGE_KUTTA"},
									{"JOINT_VALUE","(int)OpenHRP::DynamicsSimulator::JOINT_VALUE"},
									{"JOINT_VELOCITY","(int)OpenHRP::DynamicsSimulator::JOINT_VELOCITY"},
									{"JOINT_ACCELERATION","(int)OpenHRP::DynamicsSimulator::JOINT_ACCELERATION"},
									{"JOINT_TORQUE","(int)OpenHRP::DynamicsSimulator::JOINT_TORQUE"}
								},
								customFunctionsToRegister={'setSimulatorParam'},
								properties={'vectorn _tempPose; @ _lastSimulatedPose'}
							},
							{
								name='Physics.DynamicsSimulator_penaltyMethod',
								className='OpenHRP::DynamicsSimulator_penaltyMethod',
								inheritsFrom='OpenHRP::DynamicsSimulator',
							},
							{
								name='Physics.DynamicsSimulator_AIST_penalty',
								className='OpenHRP::DynamicsSimulator_AIST_penalty',
								inheritsFrom='OpenHRP::DynamicsSimulator_penaltyMethod',
								ctors={'()'}
							},
							{
								name='Physics.DynamicsSimulator_gmbs_penalty',
								className='OpenHRP::DynamicsSimulator_gmbs_penalty',
								inheritsFrom='OpenHRP::DynamicsSimulator_penaltyMethod',
								ctors={'()'}
							},
							{
								name='Physics.DynamicsSimulator_gmbs',
								className='OpenHRP::DynamicsSimulator_gmbs',
								inheritsFrom='OpenHRP::DynamicsSimulator',
								ctors={'()'},
								memberFunctions={[[
								bool stepKinematic(vectorn const& ddq, vectorn const& tau, bool );
								void getContactBases(std::vector<OpenHRP::DynamicsSimulator_gmbs::ContactBasis>& basis) const;
								double calcKineticEnergy() const
								vector3 calculateCOMacc(int ichara);
								void getLCPmatrix(matrixn& A, vectorn& b);
								void getLCPsolution(vectorn& out);
								int getNumContactLinkPairs();
								void calcContactJacobian(matrixn &JtV, int numContactLinkPairs);
								void calcContactJacobianAll(matrixn &J_all, matrixn & dotJ_all, matrixn& V_all, matrixn & dot_v_all, int link_pair_count);
								void calcContactBoneIndex(int link_pair_count, intvectorn& boneIndex);
								void calcJacobian(int ichar, int ibone, matrixn& jacobian);
								void calcDotJacobian(int ichar, int ibone, matrixn& dotjacobian);
								void calcCOMjacobian(int ichar, matrixn& jacobian);
									void calcBoneDotJacobian(int ichar, int ibone, vector3 const& localpos,matrixn& jacobian, matrixn& dotjacobian);
								void calcCOMdotJacobian(int ichar, matrixn& jacobian, matrixn& dotjacobian);
								virtual void calcMassMatrix(int ichara,matrixn& );
								void calcMassMatrix2(int ichara,matrixn&, vectorn& );
								void calcMassMatrix3(int ichara,matrixn&, vectorn& );
								void test(const char* test, matrixn& out);
								void collectExternalForce(int ichara, vectorn & extForce)
								]]}
							},
							{
								name='PLDPrimVRML',
								inheritsFrom='PLDPrimSkin',
								memberFunctions={[[
								void setPoseDOF(const vectorn& poseDOF);
								void setPose(BoneForwardKinematics const& in);
								void applyAnim(const MotionDOF& motion); @ applyMotionDOF
								]]},
								wrapperCode=[[
								static void setPose(PLDPrimVRML& prim, OpenHRP::DynamicsSimulator& s, int ichara)
								{
									static Posture pose;
									OpenHRP::DynamicsSimulator::Character* c=s._characters[ichara];
									c->chain->getPoseFromLocal(pose);
									//			printf("y=%s \n", c->chain->local(5).translation.output().ptr());
									//			printf("y=%s \n", c->chain->global(5).translation.output().ptr());
									prim.SetPose(pose, *c->skeleton);
								}

								static void setMaterial(PLDPrimVRML& prim, const char* mat)
								{
									#ifndef NO_GUI
									for(int i=1; i<prim.mSceneNodes.size(); i++)
										{
											if(prim.mSceneNodes[i])
												RE::getEntity(prim.mSceneNodes[i])->setMaterialName(mat);
											}
											#endif			
										}
										]],
										staticMemberFunctions={[[
										static void setPose(PLDPrimVRML& prim, OpenHRP::DynamicsSimulator& s, int ichara)
										static void setMaterial(PLDPrimVRML& prim, const char* mat)
										]]}
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
										]]
										,
										ctors={"(const char*)"},
										staticMemberFunctions={[[
										VRMLTransform* upcast(Bone& bone)
										void VRMLloader_setTotalMass(VRMLloader & l, m_real totalMass); @ setTotalMass
										void VRMLloader_checkMass(VRMLloader& l); @ checkMass
										void VRMLloader_printDebugInfo(VRMLloader & l); @ printDebugInfo
										void VRMLloader_changeTotalMass(VRMLloader & l, m_real totalMass); @ changeTotalMass
										void VRMLTransform_scaleMass(VRMLTransform& bone, m_real scalef); @ scaleMass
										void projectAngles(vectorn & temp1); 
										const char* name(VRMLloader& l)
										]]},
										memberFunctions={
											[[
											VRMLTransform& VRMLbone(int treeIndex) const;
											void insertChildJoint(Bone& parent, const char* tchannels, const char* rchannels, const char* nameId, bool bMoveChildren);
											void _updateMeshEntity();
											vector3 calcCOM() const;
											void calcZMP(const MotionDOF& motion, matrixn & aZMP, double kernelSize);
											void exportVRML(const char* filename);
											int numHRPjoints()
											]]
										},

										--[[
										.scope
										[
										luabind::def("upcast", &VRMLloader_upcast),
										luabind::def("projectAngles", &projectAngles)
										]
										.def("_updateMeshEntity", &VRMLloader::_updateMeshEntity)
										.def("setTotalMass", &VRMLloader_setTotalMass)
										.def("checkMass", &VRMLloader_checkMass)
										.def("calcCOM", &VRMLloader::calcCOM)
										.def("changeTotalMass", &VRMLloader_changeTotalMass)
										.def("export", &VRMLloader::exportVRML)
										.def("numHRPjoints", &VRMLloader::numHRPjoints)
										.def("setPoseDOF", &VRMLloader::setPoseDOF)
										.def("getPoseDOF", &VRMLloader::getPoseDOF)
										.def("calcZMP", &VRMLloader::calcZMP)
										.def("printDebugInfo", &VRMLloader_printDebugInfo),

										]]--
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
										]]}
									},

								},
								modules={
									{
										namespace='MotionUtil',
										ifndef='NO_GUI',
										functions={[[
										MotionUtil::FullbodyIK_MotionDOF* createFullbodyIk_UTPoser(MotionDOFinfo const& info, std::vector<MotionUtil::Effector>& effectors); @ createFullbodyIkDOF_UTPoser ;adopt=true;
										]]}
									},
									{
										namespace='MPI',
ifdef='USE_MPI',
										wrapperCode=
											[[
#ifdef USE_MPI


  static int size()
  {
    int size, rc;
    rc = MPI_Comm_size(MPI_COMM_WORLD, &size);
    return size;
  }

  static int rank()
  {
    int rank, rc;
    rc = MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    return rank;
  }

  static void send(const char* msg, int i)
  {
    int rc, tag=100;
    int len=strlen(msg);
    rc = MPI_Send(&len, 1, MPI_INT, i, tag, MPI_COMM_WORLD);
    rc = MPI_Send((void*)msg, len+1, MPI_CHAR, i, tag, MPI_COMM_WORLD);
  }

  static std::string receive(int i)
  {
    int rc, tag=100;
    int len;
    rc = MPI_Recv(&len, 1, MPI_INT, i, tag, MPI_COMM_WORLD, &status);
    TString temp;
    temp.reserve(len+1);
    rc = MPI_Recv((void*)&temp[0], len+1, MPI_CHAR, status.MPI_SOURCE, tag, MPI_COMM_WORLD, &status);
    temp.updateLength();
    return std::string(temp.ptr());
  }
 
  static int source()
  {
	  return status.MPI_SOURCE;
  }
  static void test()
  {
	vectorn a(1);
	a.set(0,1);

	for(int i=0;i<1000; i++)
	{
		for(int j=0; j<1000; j++)
		{
			a(0)=a(0)+1;
		}
	}
  }
  static void test2()
  {
	int a=1;
	for(int i=0;i<1000; i++)
	{
		for(int j=0; j<1000; j++)
		{
			a=a+1;
		}
	}
  }

  #endif
											]],
											functions={[[
   static int rank()
 static int size()
  static void send(const char* msg, int i)
  static std::string receive(int i)
  static int source()
  static void test()
  static void test2()
											]]},
											enums={
											{"ANY_SOURCE","MPI_ANY_SOURCE"},
											{"ANY_TAG","MPI_ANY_TAG"}
										}
									},
									{ 
										namespace='RE',
										functions={
											[[
											PLDPrimVRML* RE::createVRMLskin(VRMLloader*pTgtSkel, bool bDrawSkeleton) @ ;adopt=true; 
											]]
										}
									}
									,{
										namespace='Physics',
										functions={
											[[
											void lqr (matrixn &k, matrixn const& a, matrixn const&b, matrixn &q, matrixn const&r) @ LQR
											]]
										}
									}
								}
							}


							function generatePhysicsBind() 
								write(
								[[
								#include "stdafx.h"
								#include "RigidBodyWin.h"
								#include "../BaseLib/utility/scoped_ptr.h"
								#include "../BaseLib/utility/configtable.h"
								#include "../BaseLib/utility/operatorString.h"
								#include "../MainLib/WrapperLua/BaselibLUA.h"
								#include "../MainLib/WrapperLua/MainlibLUA.h"
								#include "../MainLib/OgreFltk/VRMLloader.h"
								#include "../MainLib/OgreFltk/VRMLloaderView.h"
#ifdef USE_MPI
#include <mpi.h>
  static  MPI_Status status;
#endif
								#ifndef EXCLUDE_AMAP
								#include "DynamicsSimulator_UT.h"
								#include "UT_implementation/DynamicsSimulator_UT_penalty.h"

								//#include "World.h"
								#include "../sDIMS/psim.h"
								#include "../BaseLib/motion/FullbodyIK_MotionDOF.h"

								namespace MotionUtil
								{
									MotionUtil::FullbodyIK_MotionDOF* createFullbodyIk_UTPoser(MotionDOFinfo const& info, std::vector<Effector>& effectors);
								}

								#endif
								#ifdef IncludeVirtualPhysics
								#include "VP_implementation/DynamicsSimulator_VP_penalty.h"
								#endif

								#include "GMBS_implementation/DynamicsSimulator_gmbs_penalty.h"
								#include "GMBS_implementation/DynamicsSimulator_gmbs.h"
								#include "RMatrixLUA.h"

								#include "DynamicsSimulator_penaltyMethod.h"
								#include "SDFAST_implementation/DynamicsSimulator_SDFAST.h"
								#include "InertiaCalculator.h"
								#include "dependency_support/octave_wrap.h"
								#include "../../Resource/scripts/ui/RigidBodyWin/mrdplot/include/mrdplot.hpp"

								#include "AIST_implementation/DynamicsSimulator_impl.h"
								#include "AIST_implementation/DynamicsSimulator_AIST_penalty.h"
								#include "clapack_wrap.h"
								#include "SDRE.h"
								#include "../BaseLib/math/OperatorStitch.h"
								#include "quadprog.h"
								]])
								writeIncludeBlock(true)
								write([[
								class LMat;
								class LMatView;
								class LVec;
								class LVecView;
								]])
								write('#include "luna_baselib.h"')
								write('#include "luna_mainlib.h"')
								writeHeader(bindTargetPhysics)
								write([[
								void VRMLloader_setTotalMass(VRMLloader & l, m_real totalMass);
								void VRMLloader_checkMass(VRMLloader& l);
								void VRMLloader_printDebugInfo(VRMLloader & l);
								void VRMLloader_changeTotalMass(VRMLloader & l, m_real totalMass);
								void VRMLTransform_scaleMass(VRMLTransform& bone, m_real scalef);
								void projectAngles(vectorn & temp1);
								]])
								writeDefinitions(bindTargetPhysics, 'Register_physicsbind') -- input bindTarget can be non-overlapping subset of entire bindTarget 
								flushWritten('generated/luna_physics.cpp') -- write to cpp file only when there exist modifications -> no-recompile.
							end
