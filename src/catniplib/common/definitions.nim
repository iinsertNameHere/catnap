import "parsetoml"
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
        username*: string
        hostname*: string
        distro*: string
        distroId*: DistroId
        uptime*: string
        kernel*: string
        shell*: string
        desktop*: string
        memory*: string
        terminal*: string
        disk*: string
        logo*: Logo

    Config* = object
        file*: string
        stats*: TomlValueRef
        distroart*: OrderedTable[string, Logo]
        misc*: TomlValueRef

const
    STATNAMES*    = @["username", "hostname", "uptime", "distro", "kernel", "desktop", "shell", "memory", "terminal", "disk", "colors"]
    STATKEYS*     = @["icon", "name", "color"]
    CONFIGPATH*   = joinPath(getConfigDir(), "catnip/config.toml")
    DISTROSGPATH* = joinPath(getConfigDir(), "catnip/distros.toml")
