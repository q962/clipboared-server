#include <unistd.h>
#include <windows.h>
#include <io.h>
#include <stdio.h>
#include <uv.h>

int main( int argc, char** args )
{
	STARTUPINFO         si        = {};
	PROCESS_INFORMATION dns_sd_pi = {};

	ZeroMemory( &si, sizeof( si ) );
	si.cb          = sizeof( si );
	si.dwFlags     = STARTF_USESHOWWINDOW;
	si.wShowWindow = SW_HIDE;  // 隐藏窗口

	// 创建进程，lpApplicationName是你要启动的控制台程序的路径
	if ( !CreateProcess( NULL,                    // 不使用模块名，使用命令行
	                     "bin/ClipboaredServer",  // 命令行
	                     NULL,                    // 默认进程安全性
	                     NULL,                    // 默认线程安全性
	                     FALSE,                   // 不继承句柄
	                     DETACHED_PROCESS,        // 不创建新窗口
	                     NULL,                    // 使用父进程的环境块
	                     NULL,                    // 使用父进程的驱动目录
	                     &si,                     // 指向STARTUPINFO结构的指针
	                     &dns_sd_pi ) )           // 指向PROCESS_INFORMATION结构的指针
	{
		printf( "CreateProcess failed (%lu).\n", GetLastError() );
		return -1;
	}

	return 0;
}
