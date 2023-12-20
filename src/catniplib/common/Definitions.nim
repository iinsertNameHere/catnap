import json
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

when defined linux:
    const CONFIGPATH* = getHomeDir() & ".config/catnip.json"
when defined windows:
    const CONFIGPATH* = getHomeDir() & "catnip.json"

type Config* = object
    stats*: json.JsonNode
    distroart*: json.JsonNode