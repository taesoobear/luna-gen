if [ ! -d ./build_unix_dbg ];
then
	mkdir build_unix_dbg
fi
cd build_unix_dbg
cmake -D "CMAKE_BUILD_TYPE=Debug" ..
#make 2>&1 | less
make
