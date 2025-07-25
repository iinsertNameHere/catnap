import strformat
import strutils
import os

## Compilation
proc compile(release: bool) =
    var args: seq[string]
    args.add(&"--cincludes:{thisDir()}/src/extern/headers")
    args.add(&"--path:{thisDir()}/src/extern/libraries")
    args.add(&"--passC:-f")
    args.add(&"--mm:arc")
    args.add(&"--threads:on")
    args.add(&"--panics:on")
    if release:
        args.add(&"--checks:off")
        args.add(&"--verbosity:0")
        args.add(&"--hints:off")
        args.add(&"-d:danger")
        args.add(&"--opt:speed")
        args.add(&"-d:strip")
    args.add(&"--outdir:{thisDir()}/bin")
    args.add(&"{thisDir()}/src/catnap.nim")

    exec("nim c  " & args.join(" "))

proc configure() =
    var configpath = ""

    # Use XDG_CONFIG_HOME only if it is defined. Else use ~/.confg
    let XDG_CONFIG_HOME = getEnv("XDG_CONFIG_HOME")
    if XDG_CONFIG_HOME == "":
        configpath = getEnv("HOME") & "/.config/catnap/"
    else:
        configpath = XDG_CONFIG_HOME & "/catnap/"

    echo "Creating " & configpath
    if dirExists(configpath):
        echo "Configuration directory already exists, skipping..."
    else:
        mkdir(configpath)

    echo "Creating " & configpath & "config.toml"
    if fileExists(configpath & "config.toml"):
        echo "Configuration file already exists, skipping..."
    else:
        cpFile(thisDir() & "/config/config.toml", configpath & "config.toml")

    echo "Creating " & configpath & "distros.toml"
    if fileExists(configpath & "distros.toml"):
        echo "Distro art file already exists, skipping..."
    else:
        cpFile(thisDir() & "/config/distros.toml", configpath & "distros.toml")

task generate_versionctl, "Bumps the major version of catnap. Example: (1).2.3 -> 2.0.0":
    exec &"nim c -d:release --hints:off --verbosity:0 versionctl.nim"

task clean, "Cleans existing build":
    echo "\e[36;1mCleaning\e[0;0m existing build"
    rmFile(&"{thisDir()}/bin/catnap")
    rmFile(&"{thisDir()}/versionctl")

task release, "Builds the project in release mode":
    cleanTask()
    echo "\e[36;1mBuilding\e[0;0m in release mode"
    compile(true)

task debug, "Builds the project in debug mode":
    cleanTask()
    echo "\e[36;1mBuilding\e[0;0m in debug mode"
    compile(false)

task install_cfg, "Installs the config files":
    echo "\e[36;1mInstalling\e[0;0m config files"
    configure()

task install_bin, "Installs the bin file and man page:":
    echo "\e[36;1mInstalling\e[0;0m bin file"
    echo &"Copying {thisDir()}/bin/catnap to /usr/local/bin"
    if defined(linux):
      exec &"sudo install -Dm755 {thisDir()}/bin/catnap /usr/local/bin/catnap"
    else:
      exec &"sudo mkdir -p /usr/local/bin && sudo install -m755 {thisDir()}/bin/catnap /usr/local/bin/catnap"

    let
        man_1_path = "/usr/share/man/man1/catnap.1.gz"
        local_1_path = &"{thisDir()}/docs/catnap.1"

        man_5_path = "/usr/share/man/man5/catnap.5.gz"
        local_5_path = &"{thisDir()}/docs/catnap.5"

    # Install man page only if it 
    echo &"\e[36;1mInstalling\e[0;0m man page"
    # Create .gz file
    exec &"gzip -kf {local_1_path}"
    exec &"gzip -kf {local_5_path}"

    # If man page dose not exist or there is a new version, install the new man page
    if not fileExists(man_1_path) or readFile(local_1_path & ".gz") != readFile(man_1_path):
        echo &"Copying {local_1_path} to /usr/share/man/man1"
        if defined(linux):
          exec &"sudo install -Dm755 {local_1_path}.gz /usr/share/man/man1/catnap.1.gz"
        else:
          exec &"sudo mkdir -p /usr/local/share/man/man1 && sudo install -m755 {local_1_path}.gz /usr/local/share/man/man1/catnap.1.gz"
    else:
        echo &"Copying {local_1_path} to /usr/share/man/man1 - SKIPPED"

    if not fileExists(man_5_path) or readFile(local_5_path & ".gz") != readFile(man_5_path):
        echo &"Copying {local_5_path} to /usr/share/man/man5"
        if defined(linux):
          exec &"sudo install -Dm755 {local_5_path}.gz /usr/share/man/man5/catnap.5.gz"
        else:
          exec &"sudo mkdir -p /usr/local/share/man/man5 && sudo install -m755 {local_5_path}.gz /usr/local/share/man/man5/catnap.5.gz"
    else:
        echo &"Copying {local_5_path} to /usr/share/man/man5 - SKIPPED"

task uninstall, "Uninstalls the bin file and man page:":
    echo "\e[36;1mUninstalling\e[0;0m bin file"
    exec &"sudo rm /usr/local/bin/catnap"
    echo "\e[36;1mUninstalling\e[0;0m man page"
    exec &"sudo rm /usr/share/man/man1/catnap.1.gz"
    exec &"sudo rm /usr/share/man/man5/catnap.5.gz"

task install, "'release', 'install_linux' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
    install_binTask()

task setup, "'release' and 'install_cfg'":
    releaseTask()
    install_cfgTask()
