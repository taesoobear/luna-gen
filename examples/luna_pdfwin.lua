bindTarget={
	classes={
		{
			name='SelectionRectangle',
			decl='class SelectionRectangle;',
			ctors={'()'},
			wrapperCode=[[
			static double left(SelectionRectangle& w){ return w.p1.x;}
			static double top(SelectionRectangle& w){ return w.p1.y;}
			static double right(SelectionRectangle& w){ return w.p2.x;}
			static double bottom(SelectionRectangle& w){ return w.p2.y;}
			]],
			staticMemberFunctions={[[
			static double left(SelectionRectangle& w);
			static double top(SelectionRectangle& w);
			static double right(SelectionRectangle& w);
			static double bottom(SelectionRectangle& w);
			]]}
		},
		{
			name='PDFwin',
			decl='class PDFwin;',
			properties={'std::string _filename @ filename', 'int mCurrPage @ currPage'},
			memberFunctions={[[

			void getRectSize(int pageNo, int rectNo, SelectionRectangle& rect);
			void getRectImage_width(int pageNo, int rectNo, int width, CImage& image);
			void getRectImage_height(int pageNo, int rectNo, int height, CImage& image);
			void load(const char* filename);
			double getDPI_height(int pageNo, int rectNo, int height);
			double getDPI_width(int pageNo, int rectNo, int width);
			void setStatus(const char* o);
			int getNumPages();
			int getNumRects();
			double pageCropWidth(int pageNo);
			double pageCropHeight(int pageNo);
			void setCurPage(int pageNo);
			void pageChanged();
			void redraw();

			]]}
		},
	--	{	
	--		name='PDFWriter',
	--		decl='class PDFWriter;',
	--		ctors={'()'},
	--		memberFunctions={[[
	--		bool init();
	--		void addPage(CImage const& pageImage, int bpp); // currently only 4 and 8 is supported
	--		void addPageColor(CImage const& pageImage);
	--		void save(const char* fname);
	--		bool isValid()
	--		]]}
	--	},
	}
}
function generate()
	loadDefinitionDB(source_path..'/generated/luna_baselib_db.lua')
	buildDefinitionDB(bindTarget)
	writeIncludeBlock()
	write('#include "../../MainLib/WrapperLua/luna.h"')
	write('#include "../../MainLib/WrapperLua/luna_baselib.h"')
	--write('#include "../../MainLib/WrapperLua/luna_mainlib.h"')
	writeHeader(bindTarget)
	flushWritten(source_path..'/generated/luna_pdfwin.h') -- write to cpp file only when there exist modifications -> no-recompile.
	write(
	[[
	#include "stdafx.h"
	#include "PDFwin.h"
	]]);
	writeIncludeBlock()
	write('#include "../../MainLib/WrapperLua/luna.h"')
	write('#include "../../MainLib/WrapperLua/luna_baselib.h"')
	write('#include "luna_pdfwin.h"')
	writeDefinitions(bindTarget, 'Register_pdfwin') -- input bindTarget can be non-overlapping subset of entire bindTarget 
	flushWritten(source_path..'/generated/luna_pdfwin.cpp') -- write to cpp file only when there exist modifications -> no-recompile.
end
