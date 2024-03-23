import os
import strformat
import system/ctypes
import math

when defined linux:
    import strutils
    import parsecfg
    import posix_utils
    from unicode import toLower

from "../common/definitions" import DistroId

proc getDistro*(): string =
    ## Returns the name of the running linux distro
    when defined linux:
        result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") & " " & uname().machine
    when defined windows:
        result = "Windows"

proc getDistroId*(): DistroId =
    ## Returns the DistroId of the running linux distro
    when defined linux:
        if fileExists("/boot/issue.txt"): # Check if raspbian else get distroid from /etc/os-release
            result.id = "raspbian"
            result.like = "debian"
        else:
            result.id = "/etc/os-release".loadConfig.getSectionValue("", "ID").toLower()
            result.like = "/etc/os-release".loadConfig.getSectionValue("", "ID_LIKE").toLower()

    when defined windows:
        result.id = "windows"
        result.like = "nt"

proc getUptime*(): string =
    ## Returns the system uptime as a string (DAYS, HOURS, MINUTES)

    # Uptime in sec
    when defined linux:
        let uptime = "/proc/uptime".open.readLine.split(".")[0]
    when defined windows:
        proc GetTickCount64(): cint {.importc, varargs, header: "sysinfoapi.h".}
        let uptime = int(GetTickCount64().float / 1000.float)

    let
        utu = uptime.parseUInt
        uth = utu div 3600 mod 24 # hours
        utm = utu mod 3600 div 60 # minutes
        utd = utu div 3600 div 24 # days

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

proc getParentPid(pid: int): int =
    let statusFilePath = "/proc/" & $pid & "/status"
    let statusLines = readFile(statusFilePath).split("\n")
    for rawline in statusLines:
        let stat = rawline.split(":")
        if stat[0] == "PPid": # Filter CurrentProcessInfo for Parent pid
            let pPid = parseInt(stat[1].strip())
            return pPid
    return -1

proc getProcessName(pid: int): string =
    let statusLines = readFile("/proc/" & $pid & "/status").split("\n")
    for rawLine in statusLines:
        let stat = rawLine.split(":")
        if stat[0] == "Name": # Filter ParentProcessInfo for Parent Name
            return stat[1].strip()

proc getTerminal*(): string =
    ## Returns the currently running terminal emulator
    when defined linux:
        result = getCurrentProcessID().getParentPid().getParentPid().getProcessName()
        if result == "login" or result == "sshd":
            result = "tty"

    when defined windows:
        result = "PowerShell"

proc getShell*(): string =
    ## Returns the system shell
    when defined linux:
        result = getCurrentProcessID().getParentPid().getProcessName()

    when defined windows:
        result = "PowerShell"

proc getDesktop*(): string =
    ## Returns the running desktop env
    when defined linux:
        result = getEnv("XDG_CURRENT_DESKTOP")
        if result == "":
            if getEnv("XDG_SESSION_TYPE") == "tty": # Check if in tty mode (Method 1)
                result = "Headless"

        if result == "": # Check if in tty mode (Method 2)
            if getTerminal() == "tty":
                result = "Headless"

        if result == "": # Unknown desktop
                result = "Unknown"

    when defined windows:
        result = "Windows"

proc getMemory*(mb: bool): string =
    ## Returns statistics about the memory
    let 
        fileSeq: seq[string] = "/proc/meminfo".readLines(3)

        dividend: uint = if mb: 1000 else: 1024
        suffix: string = if mb: "MB" else: "MiB"

        memTotalString = fileSeq[0].split(" ")[^2]
        memAvailableString = fileSeq[2].split(" ")[^2]

        memTotalInt = memTotalString.parseUInt div dividend
        memAvailableInt = memAvailableString.parseUInt div dividend

        memUsedInt = memTotalInt - memAvailableInt
  
    result = &"{memUsedInt}/{memTotalInt} {suffix}"

proc getDisk*(): string =
    when defined linux:
        proc getTotalDiskSpace(): cfloat {.importc, varargs, header: "getDiskSpace.h".}
        proc getUsedDiskSpace(): cfloat {.importc, varargs, header: "getDiskSpace.h".}

        let total = getTotalDiskSpace().round().int()
        let used = getUsedDiskSpace().round().int()
        let percentage = ((used / total) * 100).round().int()
        result = &"{used} / {total} GB ({percentage}%)"
    
    when defined windows:
        result = "Not implemented for now..."