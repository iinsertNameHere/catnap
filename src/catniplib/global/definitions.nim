import parsetoml
import os
import tables

# Define all stats here
type
    Color* = string

    ColorSet* = object
        Black*:   Color
        Red*:     Color
        Green*:   Color
        Yellow*:  Color
        Blue*:    Color
        Magenta*: Color
        Cyan*:    Color
        White*:   Color

    DistroId* = object
        id*: string
        like*: string

    Margin = array[3, int]

    Logo* = object
        margin*: Margin
        art*: seq[string]
        isAlias*: bool

    Stat* = object
        icon*: string
        name*: string
        color*:  Color

    Stats* = object
        maxlen*: uint
        list*: Table[string, Stat]
        color_symbol*: string

    FetchInfo* = object
        list*: Table[string, proc(): string]
        disk_statnames*: seq[string]
        distroId*: DistroId
        logo*: Logo

    Config* = object
        configFile*: string
        distrosFile*: string
        stats*: TomlValueRef
        distroart*: OrderedTable[string, Logo]
        misc*: TomlValueRef

const

    # Stats
    STATNAMES*    = @["username", "hostname", "uptime", "distro",
                    "kernel", "desktop", "shell", "memory", "terminal",
                    "cpu", "gpu", "packages", "colors"]
    STATKEYS*     = @["icon", "name", "color"]
    
    # Pkg Manager
    PKGMANAGERS*  = {
        "gentoo": "emerge",
        "fedora": "dnf",
        "redhat": "yum",
        "centos": "yum",
        "ubuntu": "apt",
        "debian": "apt",
        "devuan": "apt",
        "elementary": "apt",
        "kali": "apt",
        "mint": "apt",
        "mx": "apt",
        "pop": "apt",
        "pureos": "apt",
        "android": "apt",
        "raspbian": "apt",
        "zorin": "apt",
        "opensuse": "zypper",
        "opensuse-tumbleweed": "zypper",
        "rocky": "zypper",
        "arch": "pacman",
        "archcraft": "pacman",
        "arco": "pacman",
        "artix": "pacman",
        "manjaro": "pacman",
        "endavour": "pacman",
        "hyperbola": "pacman",
        "parabola": "pacman",
        "alpine": "apk",
        "postmarketos": "apk",
        "void": "xbps",
        "nixos": "nix",
        "crux": "pkgutils",
        "guix": "guix",
        "slackware": "slpkg",
        "sourcemage": "sorcery",
        "venom": "scratchpkg",
    }.toOrderedTable
    PKGCOUNTCOMMANDS* = {
        "scratchpkg": "scratch installed | wc -l",
        "sorcery": "gaze installed | wc -l",
        "slpkg": "ls /var/log/packages | wc -l",
        "guix": "guix package --list-installed | wc -l",
        "pkgutils": "pkginfo -i | wc -l",
        "nix": "nix-env --query --installed | wc -l",
        "xbps": "xbps-query -l | wc -l",
        "emerge": "equery list '*' | wc -l",
        "dnf": "dnf list installed | wc -l",
        "yum": "yum list installed | wc -l",
        "apt": "dpkg-query -l | grep '^ii' | wc -l",
        "zypper": "rpm -qa --last | wc --l",
        "pacman": "pacman -Q | wc -l",
        "apk": "apk list --installed | wc -l",
    }.toOrderedTable

    # Files / Dirs
    CONFIGPATH*   = joinPath(getConfigDir(), "catnip/config.toml")
    DISTROSPATH*  = joinPath(getConfigDir(), "catnip/distros.toml")
    TMPPATH*      = "/tmp/catnip"


proc toTmpPath*(p: string): string =
    # Converts a path [p] into a temp path 
    return joinPath(TMPPATH, p)
