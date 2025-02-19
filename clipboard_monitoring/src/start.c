#include <windows.h>

int main( int argc, char** args )
{
	STARTUPINFO         si        = {};
	PROCESS_INFORMATION dns_sd_pi = {};

	ZeroMemory( &si, sizeof( si ) );
	si.cb          = sizeof( si );
	si.dwFlags     = STARTF_USESHOWWINDOW;
	si.wShowWindow = SW_HIDE;  // 隐藏窗口

	wchar_t commandLine[] = L"bin/ClipboaredServer";
	if ( !CreateProcess( NULL,              // 不使用模块名，使用命令行
	                     commandLine,       // 命令行
	                     NULL,              // 默认进程安全性
	                     NULL,              // 默认线程安全性
	                     FALSE,             // 不继承句柄
	                     DETACHED_PROCESS,  // 不创建新窗口
	                     NULL,              // 使用父进程的环境块
	                     NULL,              // 使用父进程的驱动目录
	                     &si,               // 指向STARTUPINFO结构的指针
	                     &dns_sd_pi ) )     // 指向PROCESS_INFORMATION结构的指针
	{
		MessageBox( NULL,                 // 父窗口句柄，NULL 表示没有父窗口
		            L"启动失败",          // 消息框中的文本
		            L"提示",              // 消息框的标题
		            MB_OK | MB_ICONERROR  // 按钮和图标类型
		);

		return -1;
	}

	return 0;
}
