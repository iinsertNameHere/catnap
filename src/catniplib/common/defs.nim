import "toml"
import os

type Color* = string

type ColorSet* = object
    Black*:   Color
    Red*:     Color
    Green*:   Color
    Yellow*:  Color
    Blue*:    Color
    Magenta*: Color
    Cyan*:    Color
    White*:   Color

type DistroId* = object
    id*: string
    like*: string

type Margin = array[3, int]

type Logo* = object
    margin*: Margin
    art*: seq[string]

type Stat* = object
    icon*: string
    name*: string
    color*:  Color

type Stats* = object
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

const STATNAMES*  = @["username", "hostname", "uptime", "distro", "kernel", "desktop", "shell"]
const STATKEYS*   = @["icon", "name", "color"]

type FetchInfo* = object
    username*: string
    hostname*: string
    distro*: string
    distroId*: DistroId
    uptime*: string
    kernel*: string
    shell*: string
    desktop*: string
    logo*: Logo

const CONFIGPATH* = joinPath(getHomeDir(), ".catnip/config.toml")

type Config* = object
    stats*: TomlValueRef
    distroart*: TomlValueRef
