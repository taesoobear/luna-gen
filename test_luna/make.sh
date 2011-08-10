if [ ! -d ./build_unix ];
then
	mkdir build_unix
fi
cd build_unix
cmake ..
#make 2>&1 | less
make
#run tests
cd ..
