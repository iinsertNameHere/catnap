import strformat
import strutils

proc compile(release: bool) =
    var args: seq[string]
    args.add(&"--cincludes:{thisDir()}/src/extern")
    if release:
        args.add(&"--verbosity:0")
        args.add(&"-d:release")
    args.add(&"--outdir:{thisDir()}/bin")
    args.add(&"{thisDir()}/src/catnip.nim")

    exec("nim c " & args.join(" "))

proc configure() =
    when defined linux:
        var configpath = ""

        # Use XDG_CONFIG_HOME only if it is defined. Else use ~/.confg 
        let XDG_CONFIG_HOME = getEnv("XDG_CONFIG_HOME")
        if XDG_CONFIG_HOME == "":
            configpath = getEnv("HOME") & "/.config/catnip/"
        else:
            configpath = XDG_CONFIG_HOME & "/catnip/"
        
    when defined windows:
        let configpath = "C:/Users/" & getEnv("USERPROFILE") & "AppData/Local/catnip/"

    echo "Creating " & configpath
    mkdir(configpath)

    echo "Creating " & configpath & "config.toml"
    cpFile(thisDir() & "/config/config.toml", configpath & "config.toml")

    echo "Creating " & configpath & "distros.toml"
    cpFile(thisDir() & "/config/distros.toml", configpath & "distros.toml")

task release, "Builds the project in release mode":
    echo "\e[36;1mBuilding\e[0;0m in release mode"
    compile(true)

task debug, "Builds the project in debug mode":
    echo "\e[36;1mBuilding\e[0;0m in debug mode"
    compile(false)

task install_cfg, "Installs the config files":
    echo "\e[36;1mInstalling\e[0;0m config files"
    configure()

when defined linux:
    task install_bin, "Installs the bin file inside /usr/local/bin":
        echo "\e[36;1mInstalling\e[0;0m bin file"
        echo &"Copying {thisDir()}/bin/catnip to /usr/local/bin"
        exec &"sudo cp {thisDir()}/bin/catnip /usr/local/bin"

    task install, "'release', 'install_bin' and 'install_cfg'":
        releaseTask()
        install_cfgTask()
        install_binTask()

task setup, "'release' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
