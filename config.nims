proc compile(srcfile: string, outdir: string, release: bool, verbose: bool) =
    var cmd = "nim c "
    if not verbose: cmd &= "--verbosity:0 "
    if release: cmd &= "-d:release "
    cmd &= "--outdir:" & outdir & " "
    cmd &= srcfile
    echo "Run '" & cmd & "'"
    exec cmd

proc configure() =
    when defined linux:
        let configpath = getEnv("XDG_CONFIG_HOME") & "/catnip/"
    when defined windows:
        let configpath = "C:/Users/" & getEnv("USERPROFILE") & "/.catnip/"

    echo "Creating " & configpath
    mkdir(configpath)
    echo "Creating " & configpath & "config.toml"
    cpFile("config.toml", configpath & "config.toml")

task release, "Builds the project in release mode":
    echo "\e[36;1mBuilding\e[0;0m in release mode"
    compile(thisDir() & "/src/catnip.nim", thisDir() & "/bin", true, false)

task debug, "Builds the project in debug mode":
    echo "\e[36;1mBuilding\e[0;0m in debug mode"
    compile(thisDir() & "/src/catnip.nim", thisDir() & "/bin", false, true)

task install, "Installs the config files":
    echo "\e[36;1mInstalling\e[0;0m config files"
    configure()

task setup, "'release' and 'install'":
    releaseTask()
    installTask()
