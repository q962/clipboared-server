add_rules("mode.debug", "mode.release")

-- xmake:2.9.8 bug
package("gtk4")
package_end()

add_requireconfs("*", {
    system = true
})

add_requires("gtk4 >=4.16", "gmodule-2.0 >=2.80", "libadwaita-1 >=1.6.2")
add_requires("sqlite3 >=3.46")
add_requires("MagickWand >=7.1")
add_requires("luajit >= 2.1")

if is_host("linux") then
    add_requires("gio-unix-2.0")
end

if is_host("windows") then

    target("rc")
    do
        set_kind("object")
        add_files("src/win.rc")

        on_load(function(target)
            target:add("includedirs", target:scriptdir())
        end)
    end

    target("start")
    do
        add_packages("libuv")
        add_files("src/start.c")
        add_ldflags("-mwindows")
        add_deps("rc")

        on_install(function(target)
            local installdir = path.absolute(target:installdir())

            os.cp(target:targetfile(), installdir)
        end)
    end
end

target("gtkclip")
do
    add_packages("gtk4", "sqlite3", "gmodule-2.0", "MagickWand", "libadwaita-1")
    if is_host("linux") then
        add_packages("gio-unix-2.0")
    end
    set_prefixname("") -- remove 'lib'
    set_kind("shared")
    add_files("src/**.c")
    if is_host("windows") then
        add_deps("rc")
    end
    remove_files("src/start.c")
    add_configfiles("src/config.h.in")
    add_includedirs("$(buildir)")
    add_imports("xmake-modules.gnome")
    add_imports("xmake-modules.LoadEnv")
    add_defines("UNICODE")

    on_load(function(target)
        import("net.http")

        target:set("configvar", "APPID", target:values("APPID"))
        target:set('configvar', "APPIDPATH", target:values("APPIDPATH"))

        local envs = LoadEnv(target)

        if is_mode("debug") then
            target:add("defines", "DEBUG");
            target:add("defines", "_PROJECT_DATA_PATH=\"" .. target:scriptdir():gsub("\\", "/") .. "/res" .. "\"");
        end

        if os.getenv("LOCALRES") then
            target:add("defines", "LOCALRES");
        end

        if is_host("windows") then
            target:add('links', 'iphlpapi', "ws2_32", "MinHook", "Gdi32")
        end

        local luajit_p = import("lib.detect.find_package")("luajit")
        if luajit_p then
            target:add("includedirs", luajit_p.includedirs)
        end

        target:add("runenvs", "PATH", target:targetdir() .. "/../bin")

        gnome.compile_resources(target, "gresources", target:scriptdir() .. "/res/gresources.xml", {"--manual-register"})
    end)

    on_install(function(target)
        local installdir = path.absolute(target:installdir())
        local installdir_share = path.join(installdir, "share")

        os.cp(target:scriptdir() .. "/res/glib-2.0", installdir_share)
        os.cp(target:scriptdir() .. "/res/applications", installdir_share)
        os.cp(target:scriptdir() .. "/res/icons", installdir_share)
        os.cp(target:scriptdir() .. "/res/" .. target:values("APPID"), installdir_share)
        os.rm(installdir_share .. "/gresources.xml")

        gnome.pack_gtk4(target);
    end)
end
