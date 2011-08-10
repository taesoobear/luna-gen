if [ ! -d ./build_unix ];
then
	cd build_unix
	rm CMakeCache.txt
	make clean
	cd ..
fi
if [ ! -d ./build_unix_dbg ];
then
	cd build_unix_dbg
	rm CMakeCache.txt
	make clean
	cd ..
fi
