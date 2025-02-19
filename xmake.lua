set_xmakever("2.9.8")

set_project("ClipboardServer")
set_version("0.1.0")

add_moduledirs(os.projectdir())

set_values('APPID', "io.github.q962.ClipboardServer")
set_values('APPIDPATH', "/io/github/q962/ClipboardServer/")

includes("clipboard_monitoring")

target("default")
do
    set_kind("phony")
    add_deps("gtkclip")
    set_rundir("$(projectdir)")

    on_load(function(target)
        import("net.http")

        local exe_suffix = is_host('windows') and ".exe" or "";

        -- download files
        os.mkdir(target:targetdir() .. "/../bin")
        os.cd(target:targetdir() .. "/../bin")
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

            os.exec("D:/a/_temp/msys64/usr/bin/find.exe")

            import("utils.archive")
            -- try {function()
            archive.extract("luvit" .. exe_suffix, "luvit_scripts", {
                extension = ".zip"
            })
            -- end}

            -- if not os.isdir("luvit_scripts/deps") then
            --     os.raise("cannot extract luvit")
            --     os.tryrm("lit" .. exe_suffix)
            -- end
        end

        -- download dnssd
        if not os.isfile("dnssd" .. exe_suffix) then
            local version = "v1.2.15"
            if is_host("windows") then
                http.download("https://github.com/q962/dnssd/releases/download/" .. version .. "/dnssd-Windows.exe",
                    "dnssd.exe")
            elseif is_host("linux") then
                http.download("https://github.com/q962/dnssd/releases/download/" .. version .. "/dnssd-Linux", "dnssd")
            end
        end

        os.cd("-")

    end)

    on_run(function(target)
        import("core.base.option")
        import("private.action.run.runenvs")

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

        _join(envs.pre, addenvs);
        _join(envs.normal, envs.post);
        _join(setenvs, envs.post);
        setenvs = envs.post

        local args = table.wrap(option.get("arguments") or target:get("runargs"))

        local exe_suffix = is_host('windows') and ".exe" or "";

        local luvit_path = target:targetdir() .. "/../bin/luvit"

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
        local installdir = path.absolute(target:installdir())
        local installdir_bin = path.join(installdir, "bin")
        local installdir_share = path.join(installdir, "share")
        local installdir_lib = path.join(installdir, "lib")

        os.mkdir(installdir_bin)
        os.mkdir(installdir_share)
        os.mkdir(installdir_lib)
    end)

    on_install(function(target)

        function cp_module(module)
            if not module then
                return
            end

            local name = module:match("^%S+")
            local lua_file_path = module:match("%((.-)%)")
            local suffix = lua_file_path:match("(%.[^%.]+)$")
            local lua_file_path_out = path.join(lua_root_path, "libs", name:gsub("[.]", "/") .. suffix);

            os.cp(lua_file_path, lua_file_path_out)
        end

        os.exec("env")

        function locarocks_copy_package(package_name)
            local rocks_output, failed = os.iorun('luarocks show ' .. package_name)
            local section_name = ""

            local up_section_name = "";
            for _, line in ipairs(rocks_output:split("\n", {
                strict = true
            })) do
                line = string.trim(line)

                if line == 'Modules:' then
                    section_name = "Modules"
                    goto continue
                elseif line == 'Depends on:' then
                    section_name = "Depends"
                    goto continue
                elseif #line == 0 then
                    if up_section_name == "Depends" then
                        break
                    end

                    goto continue
                end

                up_section_name = section_name

                if section_name == "Modules" then
                    cp_module(line)
                end
                if section_name == "Depends" then
                    local dep_name = line:match("^%S+")
                    if dep_name ~= 'lua' then
                        locarocks_copy_package(dep_name)
                    end
                end

                ::continue::
            end
        end

        locarocks_copy_package("penlight")

        local installdir = path.absolute(target:installdir())
        local installdir_bin = path.join(installdir, "bin")
        local installdir_share = path.join(installdir, "share")
        local installdir_app_share = path.join(installdir, "share", target:values("APPID"))
        local installdir_lib = path.join(installdir, "lib")

        local root_path = installdir
        local lua_root_path = path.join(root_path, "lua");
        local other_bin_path = target:targetdir() .. "/../bin/"
        local exe_suffix = is_host('windows') and ".exe" or "";

        local lit_exe = 'lit' .. exe_suffix
        local luvi_exe = 'luvi' .. exe_suffix
        local dnssd_exe = 'dnssd' .. exe_suffix

        os.trycp("./lua_server/*.lua", lua_root_path .. '/');
        os.rm(lua_root_path .. "/local-env.lua");

        os.trycp(other_bin_path .. dnssd_exe, installdir_bin)

        os.trycp(target:dep("gtkclip"):targetfile(), lua_root_path .. '/libs/');
        os.trycp(other_bin_path .. "/luvit_scripts/deps", lua_root_path)
        os.trycp(other_bin_path .. lit_exe, installdir)
        os.trycp(other_bin_path .. luvi_exe, installdir)

        os.execv(other_bin_path .. lit_exe, {"make", "lua", "bin/ClipboaredServer" .. exe_suffix, luvi_exe}, {
            curdir = installdir
        })

        os.rm(lua_root_path)
        os.rm(installdir .. "/" .. lit_exe)
        os.rm(installdir .. "/" .. luvi_exe)

        local cmd_suffix = is_host('windows') and ".cmd" or "";
        local npm_exec = "npm" .. cmd_suffix

        os.runv(npm_exec, {"install"}, {
            curdir = "web"
        })
        os.runv(npm_exec, {"run", "build"}, {
            curdir = "web"
        })

        os.cp("web/dist", installdir_app_share .. "/web")
    end)
end
