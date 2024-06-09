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
                    "cpu", "gpu", "packages", "weather", "colors"]
    STATKEYS*     = @["icon", "name", "color"]
    
    # Pkg Manager
    PKGMANAGERS*  = {
        "gentoo": "emerge",
        "fedora": "dnf",
        "mageria": "dnf",
        "nobara": "dnf",
        "redhat": "yum",
        "centos": "yum",
        "amogos": "apt",
        "ubuntu": "apt",
        "debian": "apt",
        "deepin": "apt",
        "devuan": "apt",
        "neon": "apt",
        "voyager": "apt",
        "elementary": "apt",
        "kali": "apt",
        "lite": "apt",
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
        "archbang": "pacman",
        "archcraft": "pacman",
        "arco": "pacman",
        "artix": "pacman",
        "cachy": "pacman",
        "crystal": "pacman",
        "instant": "pacman",
        "manjaro": "pacman",
        "endavour": "pacman",
        "hyperbola": "pacman",
        "parabola": "pacman",
        "reborn": "pacman",
        "xero": "pacman",
        "alpine": "apk",
        "postmarketos": "apk",
        "evolution": "xbps",
        "void": "xbps",
        "nixos": "nix",
        "crux": "pkgutils",
        "guix": "guix",
        "slackware": "slpkg",
        "solus": "eopkg",
        "sourcemage": "sorcery",
        "vanilla": "apx",
        "venom": "scratchpkg",
    }.toOrderedTable
    PKGCOUNTCOMMANDS* = {
        "apx": "apx list -i | wc -l",
        "eopkg": "eopkg list-installed | wc -l",
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
    CONFIGPATH*   = joinPath(getConfigDir(), "catnap/config.toml")
    DISTROSPATH*  = joinPath(getConfigDir(), "catnap/distros.toml")


proc getCachePath*(): string =
    result = getEnv("XDG_CACHE_HOME")
    if result != "":
        result = joinPath(result, "catnap")
    else:
        result = getEnv("HOME")
        if result != "":
            result = joinPath(result, ".cache/catnap")
        else:
            result = "/tmp/catnap"

let CACHEPATH* = getCachePath()        

proc toTmpPath*(p: string): string =
    # Converts a path [p] into a temp path 
    return joinPath(CACHEPATH, p)
