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
    exec &"doas install -Dm755 {thisDir()}/bin/catnip /usr/local/bin/catnip"

    let
        man_1_path = "/usr/share/man/man1/catnip.1.gz"
        local_1_path = &"{thisDir()}/docs/catnip.1"

        man_5_path = "/usr/share/man/man5/catnip.5.gz"
        local_5_path = &"{thisDir()}/docs/catnip.5"

    # Install man page only if it 
    echo &"\e[36;1mInstalling\e[0;0m man page"
    # Create .gz file
    exec &"gzip -kf {local_1_path}"
    exec &"gzip -kf {local_5_path}"

    # If man page dose not exist or there is a new version, install the new man page
    if not fileExists(man_1_path) or readFile(local_1_path & ".gz") != readFile(man_1_path):
        echo &"Copying {local_1_path} to /usr/share/man/man1"
        exec &"doas install -Dm755 {local_1_path}.gz /usr/share/man/man1/catnip.1.gz"
    else:
        echo &"Copying {local_1_path} to /usr/share/man/man1 - SKIPPED"

    if not fileExists(man_5_path) or readFile(local_5_path & ".gz") != readFile(man_5_path):
        echo &"Copying {local_5_path} to /usr/share/man/man5"
        exec &"doas install -Dm755 {local_5_path}.gz /usr/share/man/man5/catnip.5.gz"
    else:
        echo &"Copying {local_5_path} to /usr/share/man/man5 - SKIPPED"

task uninstall, "Uninstalls the bin file and man page:":
    echo "\e[36;1mUninstalling\e[0;0m bin file"
    exec &"doas rm /usr/local/bin/catnip"
    echo "\e[36;1mUninstalling\e[0;0m man page"
    exec &"doas rm /usr/share/man/man1/catnip.1.gz"
    exec &"doas rm /usr/share/man/man5/catnip.5.gz"

task install, "'release', 'install_linux' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
    install_binTask()

task setup, "'release' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
