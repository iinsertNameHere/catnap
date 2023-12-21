import "Toml"
import os

type DistroId* = object
    id*: string
    like*: string

type Logo* = object
    margin*: array[3, int]
    art*: seq[string]

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

const STATNAMES*  = @["username", "hostname", "uptime", "distro", "kernel", "desktop", "shell"]
const STATKEYS*   = @["icon", "name", "color"]

const CONFIGPATH* = joinPath(getHomeDir(), ".catnip/config.toml")

type Config* = object
    stats*: TomlValueRef
    distroart*: TomlValueRef
