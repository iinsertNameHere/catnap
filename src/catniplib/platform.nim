when defined linux:
    import "std/strutils"
    import "std/parsecfg"
    import "std/posix_utils"

from "common/defs" import DistroId
import os
import strformat

proc getDistro*(): string =
    ## Returns the name of the running linux distro
    when defined linux:
        result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") & " " & uname().machine
    when defined windows:
        result = "Windows"

proc getDistroId*(): DistroId =
    ## Returns the DistroId of the running linux distro
    when defined linux:
        result.id = "/etc/os-release".loadConfig.getSectionValue("", "ID")
        result.like = "/etc/os-release".loadConfig.getSectionValue("", "ID_LIKE")
    when defined windows:
        result.id = "windows"
        result.like = "nt"

when defined windows:
    proc GetTickCount64(): cint {.importc, varargs, header: "sysinfoapi.h".}

proc getUptime*(): string =
    ## Returns the system uptime as a string (DAYS, HOURS, MINUTES)
    
    # Uptime in sec
    when defined linux:
        let uptime = "/proc/uptime".open.readLine.split(".")[0]
    when defined windows:
        let uptime = int(GetTickCount64().float / 1000.float)

    let utu = uptime.parseUInt
    let uth = utu div 3600 mod 24 # hours
    let utm = utu mod 3600 div 60 # minutes
    let utd = utu div 3600 div 24 # days

    if utd == 0 and uth != 0:
      result = &"{uth}h {utm}m" # return hours and mins
    elif uth == 0 and utd == 0:
      result = &"{utm}m" # return only mins
    else:
      result = &"{utd}d {uth}h {utm}m" # return days, hours and mins

proc getHostname*(): string =
    ## Returns the system hostname
    when defined linux:
        result = uname().nodename
    when defined windows:
        result = getEnv("COMPUTERNAME")

proc getUser*(): string =
    ## Returns the current username
    when defined linux:
        result = getEnv("USER")
    when defined windows:
        result = getEnv("USERNAME")

proc getKernel*(): string =
    ## Returns the active kernel version
    when defined linux:
        result = "/proc/version".open.readLine.split(" ")[2]
    when defined windows:
        result = "nt"

proc getShell*(): string =
    ## Returns the system shell
    when defined linux:
        result = getEnv("SHELL").split("/")[^1]
    when defined windows:
        result = "powershell"

proc getDesktop*(): string =
    ## Returns the running desktop env
    when defined linux:
        result = getEnv("XDG_CURRENT_DESKTOP")
    when defined windows:
        result = "Windows"