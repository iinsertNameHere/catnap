import "toml"
import os

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

    Stat* = object
        icon*: string
        name*: string
        color*:  Color

    Stats* = object
        maxlen*: uint
        username*: Stat
        hostname*: Stat
        uptime*: Stat
        distro*: Stat
        kernel*: Stat
        desktop*: Stat
        shell*: Stat
        colors*: Stat
        color_symbol*: string

    FetchInfo* = object
        username*: string
        hostname*: string
        distro*: string
        distroId*: DistroId
        uptime*: string
        kernel*: string
        shell*: string
        desktop*: string
        logo*: Logo

    Config* = object
        stats*: TomlValueRef
        distroart*: TomlValueRef

const
    STATNAMES*  = @["username", "hostname", "uptime", "distro", "kernel", "desktop", "shell"]
    STATKEYS*   = @["icon", "name", "color"]
    CONFIGPATH* = joinPath(getHomeDir(), ".catnip/config.toml")
