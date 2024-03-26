import parsetoml
import os
import tables

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
        list*: Table[string, string]
        distroId*: DistroId
        logo*: Logo

    Config* = object
        file*: string
        stats*: TomlValueRef
        distroart*: Table[string, Logo]
        misc*: TomlValueRef

const
    STATNAMES*    = @["username", "hostname", "uptime", "distro",
                    "kernel", "desktop", "shell", "memory", "terminal",
                    "disk", "cpu", "colors"]
    STATKEYS*     = @["icon", "name", "color"]
    CONFIGPATH*   = joinPath(getConfigDir(), "catnip/config.toml")
    DISTROSGPATH* = joinPath(getConfigDir(), "catnip/distros.toml")
