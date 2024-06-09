import os
import strformat
import math
import strutils
import parsecfg
import posix_utils
import tables
import osproc
from unicode import toLower
from "../global/definitions" import DistroId, PKGMANAGERS, PKGCOUNTCOMMANDS, toTmpPath
import "../terminal/logging"

proc getDistro*(): string =
    # Returns the name of the running linux distro
    result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") & " " & uname().machine

proc getDistroId*(): DistroId =
    # Returns the DistroId of the running linux distro
    if fileExists("/boot/issue.txt"): # Check if raspbian else get distroid from /etc/os-release
        result.id = "raspbian"
        result.like = "debian"
    else:
        result.id = "/etc/os-release".loadConfig.getSectionValue("", "ID").toLower()
        result.like = "/etc/os-release".loadConfig.getSectionValue("", "ID_LIKE").toLower()

proc getUptime*(): string =
    # Returns the system uptime as a string (DAYS, HOURS, MINUTES)

    # Uptime in sec
    let uptime = "/proc/uptime".open.readLine.split(".")[0]

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
    # Returns the system hostname
    result = uname().nodename

proc getUser*(): string =
    # Returns the current username
    result = getEnv("USER")

proc getKernel*(): string =
    # Returns the active kernel version
    result = "/proc/version".open.readLine.split(" ")[2]

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
    # Returns the currently running terminal emulator
    result = getCurrentProcessID().getParentPid().getParentPid().getProcessName()
    if result == "login" or result == "sshd":
        result = "tty"

proc getShell*(): string =
    # Returns the system shell
    result = getCurrentProcessID().getParentPid().getProcessName()

proc getDesktop*(): string =
    # Returns the running desktop env
    result = getEnv("XDG_CURRENT_DESKTOP") # Check Current Desktop (Method 1)

    if result == "": # Check Current Desktop (Method 2)
        result = getEnv("XDG_SESSION_DESKTOP")

    if result == "": # Check Current Desktop (Method 3)
        result = getEnv("DESKTOP_SESSION")

    if result == "": # Check if in tty mode (Method 1)
        if getEnv("XDG_SESSION_TYPE") == "tty":
            result = "Headless"

    if result == "": # Check if in tty mode (Method 2)
        if getTerminal() == "tty":
            result = "Headless"

    if result == "": # Default to Unknown
        result = "Unknown"

proc getMemory*(mb: bool = true): string =
    # Returns statistics about the memory
    let 
        fileSeq: seq[string] = "/proc/meminfo".readLines(3)

        dividend: uint = if mb: 1000 else: 1024
        suffix: string = if mb: "MB" else: "MiB"

        memTotalString = fileSeq[0].split(" ")[^2]
        memAvailableString = fileSeq[2].split(" ")[^2]

        memTotalInt = memTotalString.parseUInt div dividend
        memAvailableInt = memAvailableString.parseUInt div dividend

        memUsedInt = memTotalInt - memAvailableInt
        percentage = ((int(memUsedInt) / int(memTotalInt)) * 100).round().int()

    result = &"{memUsedInt} / {memTotalInt} {suffix} ({percentage}%)"

proc getMounts*(): seq[string] =
    proc getMountPoints(): cstring {.importc, varargs, header: "getDisk.h".}

    let mounts_raw = $getMountPoints()
    if mounts_raw == "":
        logError("Failed to get disk mounting Points")

    let mounts = mounts_raw.split(',')

    for mount in mounts:
        if mount == "":
            continue
        
        if not mount.startsWith("/run/media"):
            if mount.startsWith("/proc") or
            mount.startsWith("/run")     or
            mount.startsWith("/sys")     or
            mount.startsWith("/tmp")     or
            mount.startsWith("/boot")    or
            mount.startsWith("/dev"):
                continue

        result.add(mount)

proc getDisk*(mountingPoint: ref string): string =
    # Returns disk space usage
    proc getTotalDiskSpace(mountingPoint: cstring): cfloat {.importc, varargs, header: "getDisk.h".}
    proc getUsedDiskSpace(mountingPoint: cstring): cfloat {.importc, varargs, header: "getDisk.h".}

    let
        total = getTotalDiskSpace(mountingPoint[].cstring).round().int()
        used = getUsedDiskSpace(mountingPoint[].cstring).round().int()
        percentage = ((used / total) * 100).round().int()
    result = &"{used} / {total} GB ({percentage}%)"

proc getCpu*(): string =
    # Returns CPU model
    let rawLines = readFile("/proc/cpuinfo").split("\n")
    
    var key_name = "model name"
    if getDistroId().id == "raspbian": key_name = "Model"

    for rawLine in rawLines:
        let line = rawLine.split(":")

        if line.len < 2: continue

        let
            key  = line[0].strip()
            val  = line[1].strip()
        if key == key_name: 
            result = val
            break

proc getPkgManager(distroId: DistroId): string =
    # Returns main package manager of distro
    for key in PKGMANAGERS.keys:
        if distroId.id == key:
            return PKGMANAGERS[key]

    for key in PKGMANAGERS.keys:
        if distroId.like == key:
            return PKGMANAGERS[key]
    
    return "unknown"

proc getPackages*(distroId: DistroId = getDistroId()): string =
    # Return install package count of the main package manager of the distro
    let pkgManager = getPkgManager(distroId)
    if pkgManager == "unknown":
        return "unknown"

    var foundPkgCmd = false
    for key in PKGCOUNTCOMMANDS.keys:
        if pkgManager == key:
            foundPkgCmd = true
            break
    if not foundPkgCmd:
        return "unknown"

    let tmpFile = "pkgcount.txt".toTmpPath

    let cmd: string = PKGCOUNTCOMMANDS[pkgManager] & " > " & tmpFile
    if execCmd(cmd) != 0:
        logError("Failed to fetch pkg count!")
    
    let count = readFile(tmpFile).strip()
    return count & " [" & pkgManager & "]" 

proc getGpu*(): string =
    # Returns the VGA line of lspci output
    let tmpFile = "lspci.txt".toTmpPath
    
    if not fileExists(tmpFile):
        if execCmd("lspci > " & tmpFile) != 0:
            logError("Failed to fetch GPU!")

    var vga = ""
    let lspci = readFile(tmpFile)
    for line in lspci.split('\n'):
        if line.split(' ')[1] == "VGA":
            vga = line
            break

    if vga == "":
        return "Unknown"

    let vga_parts = vga.split(":")

    if vga_parts.len < 2: 
        return "Unknown"

    let gpu = vga_parts[vga_parts.len - 1].split("(")[0]
    return gpu.strip()

proc getWeather*(): string =
    let tmpFile = "weather.txt".toTmpPath
    if execCmd("curl -s wttr.in/?format=3 > " & tmpFile) != 0:
        logError("Failed to fetch weather!")

    # Returns the weather and discards the annoying newline.
    let weather = readFile(tmpFile)
    result = $weather.replace("\n", "")
