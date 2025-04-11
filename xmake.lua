set_xmakever("2.9.8")

set_project("ClipboardServer")
set_version("0.1.0")

add_moduledirs(os.projectdir())

set_config('APPID', "io.github.q962.ClipboardServer")
set_config('APPIDPATH', "/io/github/q962/ClipboardServer/")

includes("clipboard_monitoring")

add_imports("xmake-modules.gnome")
add_imports("xmake-modules.LoadEnv")
add_imports("xmake-modules.utils")

local exe_suffix = is_host('windows') and ".exe" or "";
local dll_suffix = is_host('windows') and ".dll" or ".so";

target("default")
do
    set_kind("phony")
    add_deps("gtkclip")
    set_rundir("$(projectdir)")

    add_installfiles("web/dist/(**)", {
        prefixdir = "share/" .. (get_config('APPID') or "") .. "/web"
    })

    add_installfiles("build/bin/dnssd*", {
        prefixdir = "bin"
    })

    add_installfiles("build/bin/ClipboaredServer*", {
        prefixdir = "bin"
    })

    on_load(function(target)
        import("net.http")

        -- download files
        os.mkdir("$(buildir)/bin")
        os.cd("$(buildir)/bin")
        if not os.isfile("lit" .. exe_suffix) then
            if is_host('windows') then
                http.download("https://github.com/luvit/lit/raw/master/get-lit.ps1", "get-lit.ps1")
                local temp = os.getenv("TEMP")
                local tmp = os.getenv("TMP")
                os.setenv("TEMP", nil)
                os.setenv("TMP", nil)
                os.run('powershell ./get-lit.ps1')
                os.setenv("TEMP", temp)
                os.setenv("TMP", tmp)
            else
                http.download("https://github.com/luvit/lit/raw/master/get-lit.sh", "get-lit.sh")
                os.run('sh ./get-lit.sh')
            end
        end

        -- download dnssd
        if not os.isfile("dnssd" .. exe_suffix) then
            local version = "v1.2.15"
            if is_host("windows") then
                http.download("https://github.com/q962/dnssd/releases/download/" .. version .. "/dnssd-Windows.exe",
                    "dnssd.exe")
            elseif is_host("linux") then
                http.download("https://github.com/q962/dnssd/releases/download/" .. version .. "/dnssd-Linux", "dnssd")
                os.run("chmod u+x dnssd")
            end
        end

        os.cd("-")

    end)

    on_run(function(target)
        import("core.base.option")
        import("private.action.run.runenvs")

        gnome.compile_schemas("clipboard_monitoring/res/glib-2.0/schemas")

        local envs = import("xmake-modules.LoadEnv")(target)

        local rundir = target:rundir()
        local addenvs, setenvs = runenvs.make(target)

        -- 让 t1 在 t2 之前，修改 t2
        function _join(t1, t2)
            for name, v in pairs(t1) do
                t2[name] = t2[name] or {};
                if type(v) == "table" then
                    t2[name] = table.join(v, t2[name])
                else
                    table.insert(t2[name], 1, v);
                end
            end
        end

        addenvs.PATH = vformat("$(buildir)/bin")

        _join(envs.pre, addenvs);
        _join(envs.normal, envs.post);
        _join(setenvs, envs.post);
        setenvs = envs.post

        setenvs.LUA_PATH = path.translate(os.iorun("env luarocks path --lr-path")):trim()
        setenvs.LUA_CPATH = path.absolute(target:targetdir()) .. "/?" .. dll_suffix
        setenvs.WEBROOT = path.absolute(os.projectdir()) .. "/web/dist"
        setenvs.PROJECT_PREFIX = path.absolute(os.projectdir()) .. '/clipboard_monitoring/res/'

        local args = table.wrap(option.get("arguments") or target:get("runargs"))

        local luvit_path = vformat("$(buildir)/bin/luvit")

        if option.get("debug") then

            import("core.base.signal")
            signal.register(signal.SIGINT, function(signo)
                print("signal.SIGINT(%d)", signo)
            end)

            os.execv("gdb", {"-ex", "set args lua_server/main.lua " .. table.concat(args, " "), "--args",
                             vformat(luvit_path .. exe_suffix)}, {
                curdir = rundir,
                addenvs = addenvs,
                setenvs = setenvs
            })
        else
            os.execv(luvit_path .. exe_suffix, table.join({"lua_server/main.lua"}, args), {
                curdir = rundir,
                detach = option.get("detach"),
                addenvs = addenvs,
                setenvs = setenvs
            })
        end
    end)

    before_install(function(target)

        local installdir = path.absolute(target:installdir()) .. "/"
        local other_bin_path = path.absolute(vformat("$(buildir)/bin")) .. "/"

        try {function()
            import("utils.archive")
            archive.extract(other_bin_path .. "luvit" .. exe_suffix, other_bin_path .. "luvit_scripts", {
                extension = ".zip"
            })
        end}
        os.rm(other_bin_path .. "luvit_scripts/init.lua");

        local lua_root_path = vformat("$(buildir)/bin/luvit_scripts/")
        local lua_libs_path = lua_root_path .. "libs/"

        local lit_exe = 'lit' .. exe_suffix
        local luvi_exe = 'luvi' .. exe_suffix

        local deploy_lib_dir = string.trim(os.iorun("env luarocks config deploy_lib_dir"))
        local deploy_lua_dir = string.trim(os.iorun("env luarocks config deploy_lua_dir"))
        os.cp(deploy_lua_dir .. "/pl", lua_libs_path)
        os.cp(deploy_lib_dir .. "/lfs.*", lua_libs_path)

        os.cp("./lua_server/*.lua", lua_root_path);
        os.rm(lua_root_path .. "/local-env.lua");

        os.cp(target:dep("gtkclip"):targetfile(), lua_libs_path);

        os.execv(other_bin_path .. luvi_exe, { --
        other_bin_path .. "luvit_scripts", --
        "-o", --
        other_bin_path .. "ClipboaredServer" .. exe_suffix --
        })

        local cmd_suffix = is_host('windows') and ".cmd" or "";
        local npm_exec = "npm" .. cmd_suffix

        if not os.isdir("web/dist") then
            os.runv(npm_exec, {"install"}, {
                curdir = "web"
            })
            os.runv(npm_exec, {"run", "build"}, {
                curdir = "web"
            })
        end
    end)
end
