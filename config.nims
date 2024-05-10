import strformat
import strutils
import os

proc compile(release: bool) =
    var args: seq[string]
    args.add(&"--cincludes:{thisDir()}/src/extern/headers")
    args.add(&"--path:{thisDir()}/src/extern/libraries")
    if release:
        args.add(&"--verbosity:0")
        args.add(&"-d:release")
    args.add(&"--outdir:{thisDir()}/bin")
    args.add(&"{thisDir()}/src/catnip.nim")

    exec("nim c  " & args.join(" "))

proc configure() =
    var configpath = ""

    # Use XDG_CONFIG_HOME only if it is defined. Else use ~/.confg
    let XDG_CONFIG_HOME = getEnv("XDG_CONFIG_HOME")
    if XDG_CONFIG_HOME == "":
        configpath = getEnv("HOME") & "/.config/catnip/"
    else:
        configpath = XDG_CONFIG_HOME & "/catnip/"

    echo "Creating " & configpath
    mkdir(configpath)

    echo "Creating " & configpath & "config.toml"
    cpFile(thisDir() & "/config/config.toml", configpath & "config.toml")

    echo "Creating " & configpath & "distros.toml"
    cpFile(thisDir() & "/config/distros.toml", configpath & "distros.toml")

task release, "Builds the project in release mode":
    echo "\e[36;1mBuilding\e[0;0m in release mode"
    exec &"./scripts/git-commit-id.sh"
    compile(true)

task debug, "Builds the project in debug mode":
    echo "\e[36;1mBuilding\e[0;0m in debug mode"
    exec &"./scripts/git-commit-id.sh"
    compile(false)

task install_cfg, "Installs the config files":
    echo "\e[36;1mInstalling\e[0;0m config files"
    configure()

task install_bin, "Installs the bin file and man page:":
    echo "\e[36;1mInstalling\e[0;0m bin file"
    echo &"Copying {thisDir()}/bin/catnip to /usr/local/bin"
    exec &"sudo install -Dm755 {thisDir()}/bin/catnip /usr/local/bin"

    let
        man_path = "/usr/share/man/man1/catnip.1.gz"
        local_path = &"{thisDir()}/docs/catnip.1"

    # Install man page only if it 
    echo &"\e[36;1mInstalling\e[0;0m man page" 
    exec &"gzip -kf {local_path}" # Create .gz file

    # If man page dose not exist or there is a new version, install the new man page
    if not fileExists(man_path) or readFile(local_path & ".gz") != readFile(man_path):
        echo &"Copying {local_path} to /usr/share/man/man1"
        exec &"sudo install -Dm755 {local_path}.gz /usr/share/man/man1"
    else:
        echo &"Copying {local_path} to /usr/share/man/man1 - SKIPPED"

task uninstall, "Uninstalls the bin file and man page:":
    echo "\e[36;1mUninstalling\e[0;0m bin file"
    exec &"sudo rm /usr/local/bin/catnip"
    echo "\e[36;1mUninstalling\e[0;0m man page"
    exec &"sudo rm /usr/share/man/man1/catnip.1.gz"

task install, "'release', 'install_linux' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
    install_binTask()

task setup, "'release' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
