#include <stdio.h>
#include <windows.h>

// int main( int argc, char** args )
// {
// 	HMODULE hModule = LoadLibrary( TEXT( "build\\mingw\\x86_64\\debug\\gtkclip.dll" ) );
// 	if ( hModule == NULL ) {
// 		// 获取加载失败的错误代码
// 		DWORD errorCode = GetLastError();
// 		// 处理错误
// 		TCHAR buffer[ 1024 ];
// 		FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
// 		               NULL,
// 		               errorCode,
// 		               MAKELANGID( LANG_NEUTRAL, SUBLANG_DEFAULT ),
// 		               buffer,
// 		               1024,
// 		               NULL );

// 		printf( "error: %ls", buffer );
// 		// 使用buffer中的错误描述
// 	}

// 	if ( hModule != NULL ) {
// 		FreeLibrary( hModule );
// 	}

// 	return 0;
// }
 __declspec(dllexport)
int luaopen_libtest()
{
	return 0;
}