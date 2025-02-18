#include "res-utils.h"
#include <unistd.h>

const char* gres_path_translate( const char* path )
{
	static char _path_buf[ 4096 ] = "";
	if ( !path )
		return NULL;

	if ( path[ 0 ] == '/' ) {
		path = path + 1;
	}

	g_snprintf( _path_buf, sizeof( _path_buf ) - 1, APPIDPATH "%s", path );

	return _path_buf;
}

static void _va_append( GString* path, const char* arg1, va_list v_args )
{
	va_list args;
	va_copy( args, v_args );

	const char* arg = arg1;
	do {
		if ( !arg )
			break;

		if ( arg[ 0 ] == '\0' )
			goto _continue;

		if ( arg[ 0 ] != '/' || arg[ 0 ] != '\\' )
			g_string_append( path, G_DIR_SEPARATOR_S );
		g_string_append( path, arg );
	_continue:;
	} while ( ( arg = va_arg( args, const char* ) ) );

	va_end( args );
}

const char* app_prefix_path( const char* path, ... )
{
	static GString* prefix_path        = NULL;
	static guint    prefix_path_length = 0;
	if ( g_once_init_enter_pointer( ( gpointer* )&prefix_path ) ) {
		GString* str = g_string_new( NULL );

#if defined( INSTALL_PATH ) && defined( G_OS_WIN32 )
		g_string_append( str, INSTALL_PATH );
#else
		const char* exe_path = app_exe_path( NULL );
		g_string_append( str, exe_path );

		char* sep = g_utf8_strrchr( str->str, str->len, '/' );
		if ( !sep )
			g_utf8_strrchr( str->str, str->len, '\\' );

		if ( sep ) {
			g_string_set_size( str, sep - str->str );
		}
#endif

		prefix_path_length = str->len;

		g_once_init_leave_pointer( ( gpointer* )&prefix_path, str );
	}

	g_string_set_size( prefix_path, prefix_path_length );

	va_list args;
	va_start( args, path );
	_va_append( prefix_path, path, args );
	va_end( args );

	return prefix_path->len > 0 ? prefix_path->str : NULL;
}

const char* app_exe_path( const char* path, ... )
{
	static GString* exe_path        = NULL;
	static guint    exe_path_length = 0;
	if ( g_once_init_enter_pointer( ( gpointer* )&exe_path ) ) {
		GString* str = g_string_new( NULL );

#ifdef G_OS_WIN32
		{
			wchar_t* path   = g_malloc( 4096 );
			DWORD    result = GetModuleFileNameW( NULL, path, 4096 - 1 );

			g_return_val_if_fail( result, NULL );

			result = result * sizeof( wchar_t );

			GError* error    = NULL;
			char*   execpath = g_convert( ( const char* )path, result, "utf-8", "utf-16", NULL, NULL, &error );
			if ( error ) {
				g_error( _( "启动程序失败，未能获取程序路径: %s" ), error->message );
				g_error_free( error );
			}

			char* _exec_dir_path = g_path_get_dirname( execpath );
			char* p              = strrchr( _exec_dir_path, '/' );
			if ( p )
				*p = '\0';
			else {
				p = strrchr( _exec_dir_path, '\\' );
				if ( p )
					*p = '\0';
			}

			g_string_append( str, _exec_dir_path );

			g_free( execpath );
			g_free( _exec_dir_path );
		}
#elif defined( G_OS_UNIX )
		{
			g_string_set_size( str, 1024 );
			int ret = readlink( "/proc/self/exe", str->str, 1023 );
			if ( ret == -1 ) {
				g_error( "/proc/self/exe" );
			}
			else
				g_string_set_size( str, ret - 4 );
		}
#else
#error unsupport
#endif

		exe_path_length = str->len;

		g_once_init_leave_pointer( ( gpointer* )&exe_path, str );
	}

	g_string_set_size( exe_path, exe_path_length );

	va_list args;
	va_start( args, path );
	_va_append( exe_path, path, args );
	va_end( args );

	return exe_path->len > 0 ? exe_path->str : NULL;
}

const char* app_libexec_path( const char* path, ... )
{
	static GString* libexec_path        = NULL;
	static guint    libexec_path_length = 0;
	if ( g_once_init_enter_pointer( ( gpointer* )&libexec_path ) ) {
		GString* str = g_string_new( NULL );

#if defined( G_OS_WIN32 ) && defined( LIBEXEC )
		g_string_append( str, LIBEXEC G_DIR_SEPARATOR_S );
#else
		const char* prefix_path = app_prefix_path( NULL );
		g_string_append( str, prefix_path );

#ifdef G_OS_WIN32
		g_string_append( str, G_DIR_SEPARATOR_S "bin" G_DIR_SEPARATOR_S );
#else
		g_string_append( str, G_DIR_SEPARATOR_S "libexec" G_DIR_SEPARATOR_S );
#endif

#endif
		libexec_path_length = str->len;

		g_once_init_leave_pointer( ( gpointer* )&libexec_path, str );
	}

	g_string_set_size( libexec_path, libexec_path_length );

	va_list args;
	va_start( args, path );
	_va_append( libexec_path, path, args );
	va_end( args );

	return libexec_path->len > 0 ? libexec_path->str : NULL;
}

const char* app_installed_share_path( const char* path, ... )
{
	static GString* share_path        = NULL;
	static guint    share_path_length = 0;
	if ( g_once_init_enter_pointer( ( gpointer* )&share_path ) ) {
		GString* str = g_string_new( NULL );

#if defined( DEBUG ) || defined( LOCALRES )
		const char* path = g_getenv( "_project_data_path" );
		if ( path ) {
			g_string_append( str, path );
		}
		else
#ifdef _PROJECT_DATA_PATH
		  if ( sizeof( _PROJECT_DATA_PATH ) > 1 ) {
			g_string_append( str, _PROJECT_DATA_PATH );
		}
		else
#endif

#endif
		{
			const char* prefix_path = app_prefix_path( NULL );
			g_string_append( str, prefix_path );
			g_string_append( str, G_DIR_SEPARATOR_S "share" );
		}

		share_path_length = str->len;

		g_once_init_leave_pointer( ( gpointer* )&share_path, str );
	}

	g_string_set_size( share_path, share_path_length );

	va_list args;
	va_start( args, path );
	_va_append( share_path, path, args );
	va_end( args );

	return share_path->len > 0 ? share_path->str : NULL;
}

const char* app_share_path_translate( const char* path, ... )
{
	static GString* app_share_path        = NULL;
	static guint    app_share_path_length = 0;
	if ( g_once_init_enter_pointer( ( gpointer* )&app_share_path ) ) {
		GString* path = NULL;
		GFile*   file = NULL;

		G_STMT_START
		{
			const char* installed_share_path = app_installed_share_path( NULL );
			if ( installed_share_path ) {
				file = g_file_new_build_filename( installed_share_path, APPID, NULL );
				if ( g_file_query_file_type( file, G_FILE_QUERY_INFO_NONE, NULL ) == G_FILE_TYPE_DIRECTORY ) {
					break;
				}
				g_set_object( ( gpointer* )&file, NULL );
			}

			const char* const* dirs = g_get_system_data_dirs();
			for ( const char* const* dir = dirs; dirs && *dir; dir++ ) {
				file = g_file_new_build_filename( *dir, APPID, NULL );
				if ( g_file_query_file_type( file, G_FILE_QUERY_INFO_NONE, NULL ) == G_FILE_TYPE_DIRECTORY ) {
					break;
				}
				g_set_object( ( gpointer* )&file, NULL );
			}
		}
		G_STMT_END;

		if ( file ) {
			path = g_string_new( g_file_get_path( file ) );

			app_share_path_length = path->len;
			g_object_unref( file );
		}

		g_once_init_leave_pointer( ( gpointer* )&app_share_path, path );
	}

	g_string_set_size( app_share_path, app_share_path_length );

	if ( path && path[ 0 ] == '/' ) {
		path = path + 1;
	}

	va_list args;
	va_start( args, path );
	_va_append( app_share_path, path, args );
	va_end( args );

	return app_share_path->str;
}

const char* app_data_path_translate( const char* path, ... )
{
	static GString* app_data_path        = NULL;
	static gsize    app_data_path_length = 0;

	if ( g_once_init_enter_pointer( ( gpointer* )&app_data_path ) ) {
		const char* user_data_dir = g_get_user_data_dir();

		GString* path = g_string_new( user_data_dir );
		g_string_append( path, G_DIR_SEPARATOR_S APPID );

		app_data_path_length = path->len;

		g_once_init_leave_pointer( ( gpointer* )&app_data_path, path );
	}

	g_string_set_size( app_data_path, app_data_path_length );

	va_list args;
	va_start( args, path );
	_va_append( app_data_path, path, args );
	va_end( args );

	return app_data_path->str;
}
