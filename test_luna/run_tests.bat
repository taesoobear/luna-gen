echo off
@echo off
cd bin
cd Release
echo "____________________________"
echo "test_simple\n"
test_simple
echo "____________________________"
echo "test_garbage_collection\n"
test_garbage_collection
echo "____________________________"
echo "test_var_arg\n"
test_var_arg
echo "____________________________"
echo "test_property\n"
test_property
echo "____________________________"
echo "test_inheritance\n"
test_inheritance
echo "____________________________"
echo "test_inheritance_from_lua\n"
test_inheritance_from_lua
