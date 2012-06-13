if [  -d ./build_unix ];
then
	cd build_unix
	rm -rf *
	cd ..
fi
if [ -d ./build_unix_dbg ];
then
	cd build_unix_dbg
	rm -rf *
	cd ..
fi
