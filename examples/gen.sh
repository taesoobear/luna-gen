# first generate luna_baselib.* and luna_mainlib.*
lua ../luna_gen.lua luna_baselib.lua

# then generate luna_pdfwin.*
# note that all the classes defined in luna_pdfwin.lua is dependent on luna_baselib and luna_mainlib
# to do this, 
# use in luna_baselib.lua 
#		writeDefinitionDBtoFile(source_path..'/generated/luna_baselib_db.lua')

# and in luna_pdfwin.lua
#       loadDefinitionDB(source_path..'/generated/luna_baselib_db.lua')
lua ../luna_gen.lua luna_pdfwin.lua
