import os
import strformat
import math
import strutils
from parsecfg import loadConfig, getSectionValue
import posix_utils
import times
import tables
import osproc
import nre
from unicode import toLower
from "../global/definitions" import DistroId, PKGMANAGERS, PKGCOUNTCOMMANDS, toCachePath, toTmpPath, Config
import "../terminal/logging"
import parsetoml
import "caching"
import algorithm

proc getDistro*(): string =
    let cacheFile = "distroname".toCachePath
    result = readCache(cacheFile)
    if result != "": return

    when defined(linux) or defined(bsd):
    # Returns the name of the running linux distro
        result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") & " " & uname().machine
    elif defined(macosx):
        result = "MacOS X" & " " & uname().machine
    else:
        result = "Unknown"

    writeCache(cacheFile, result, INFINITEDURATION)

proc getDistroId*(): DistroId =
    let cacheFile = "distroid".toCachePath
    let raw = readCache(cacheFile)
    if raw != "":
        let raw_vals = raw.split(':')
        if raw_vals.len == 2:
            result.id = raw_vals[0].replace(" ", "_")
            result.like = raw_vals[1].replace(" ", "_")

    if defined(linux) or defined(bsd):
        if fileExists("/boot/issue.txt"): # Check if raspbian else get distroid from /etc/os-release
            result.id = "raspbian"
            result.like = "debian"
        else:
            result.id = "/etc/os-release".loadConfig.getSectionValue("", "ID").toLower()
            result.like = "/etc/os-release".loadConfig.getSectionValue("", "ID_LIKE").toLower()
    elif defined(macosx):
        result.id = "macos"
        result.like = "macos"
    else:
        result.id = "Unknown"
        result.like = "Unknown"
    writeCache(cacheFile, &"{result.id}|{result.like}", INFINITEDURATION)

proc getUptime*(): string =
    # Returns the system uptime as a string (DAYS, HOURS, MINUTES)

    # Uptime in sec
    var utu: int
    if defined(linux) or defined(bsd):
        let uptime = "/proc/uptime".open.readLine.split(".")[0]
        utu = uptime.parseInt
    else:
      let
          boottime = execProcess("sysctl -n kern.boottime").split(" ")[3].split(",")[0]
          now = epochTime()
      utu = toInt(now) - parseInt(boottime)

    let
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
    result = uname().release

proc getParentPid(pid: int): int =
    if defined(linux) or defined(bsd):
        let statusFilePath = "/proc/" & $pid & "/status"
        let statusLines = readFile(statusFilePath).split("\n")
        for rawline in statusLines:
            let stat = rawline.split(":")
            if stat[0] == "PPid": # Filter CurrentProcessInfo for Parent pid
                let pPid = parseInt(stat[1].strip())
                return pPid
    elif defined(macosx):
        let pPid = execProcess("ps -o ppid -p " & $pid).split("\n")[1]
        return parseInt(pPid)
    else:
        return -1

proc getProcessName(pid: int): string =
    if defined(linux) or defined(bsd):
        let statusLines = readFile("/proc/" & $pid & "/status").split("\n")
        for rawLine in statusLines:
            let stat = rawLine.split(":")
            if stat[0] == "Name": # Filter ParentProcessInfo for Parent Name
                return stat[1].strip()
    elif defined(macosx):
        let cmd = execProcess("ps -o comm -p " & $pid).split("\n")[1]
        return cmd.split("/")[^1] # Strip away command path
    else:
        return "Unknown"

proc getTerminal*(): string =
    # Returns the currently running terminal emulator
    if defined(linux) or defined(bsd):
        result = getCurrentProcessID().getParentPid().getParentPid().getProcessName()
        if result == "login" or result == "sshd":
            result = "tty"
    elif defined(macosx):
        result = getEnv("TERM_PROGRAM")
    else:
        result = "Unknown"

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
        dividend: uint = if mb: 1000 else: 1024
        suffix: string = if mb: "MB" else: "MiB"
    if defined(linux) or defined(bsd):
        let
            fileSeq: seq[string] = "/proc/meminfo".readLines(3)

            memTotalString = fileSeq[0].split(" ")[^2]
            memAvailableString = fileSeq[2].split(" ")[^2]

            memTotalInt = memTotalString.parseUInt div dividend
            memAvailableInt = memAvailableString.parseUInt div dividend

            memUsedInt = memTotalInt - memAvailableInt
            percentage = ((int(memUsedInt) / int(memTotalInt)) * 100).round().int()

        result = &"{memUsedInt} / {memTotalInt} {suffix} ({percentage}%)"
    elif defined(macosx):
        # The computation of free memory is very subjective on MacOS; multiple system utilites, ie vm_stat, top, memory_pressure, sysctl, all give different results
        # Here memory_pressure is used since it shows the most resemblance to the graph in the Activity Monitor
        let
            memPressureRaw = execProcess("memory_pressure").split("\n")

            memTotalString = memPressureRaw[0].split(" ")[3]
            freePercenString = memPressureRaw[^2].split(" ")[^1]

            memTotalInt = memTotalString.parseUInt div 1024 div dividend
            freePercentInt = parseUInt(freePercenString[0..^2]) # This string comes with a % sign at the end
            memUsedInt = memTotalInt * (100 - freePercentInt) div 100

        result = &"{memUsedInt} / {memTotalInt} {suffix} ({100 - freePercentInt}%)"
    else:
        result = "Unknown"

proc getBattery*(): string =
    if defined(linux) or defined(bsd):
        # Credits to https://gitlab.com/prashere/battinfo for regex implementation.
        let powerPath = "/sys/class/power_supply/"

        var batterys: seq[tuple[idx: int, path: string]]

        # Collect all batterys
        for dir in os.walk_dir(powerPath):
            if os.last_path_part(dir.path).contains(nre.re"^BAT\d+$"):
                let batteryPath = dir.path & "/"
                # Only check if battery has capacity and status
                if fileExists(batteryPath & "capacity") and fileExists(batteryPath & "status"):
                    batterys.add((parseInt($dir.path[^1]), batteryPath))

        if batterys.len < 1:
            logError("No battery detected!")

        # Sort batterys by number
        sort(batterys)

        # Get stats for battery with lowest number
        let
            batteryCapacity = readFile(batterys[0].path & "capacity").strip()
            batteryStatus = readFile(batterys[0].path & "status").strip()

        result = &"{batteryCapacity}% ({batteryStatus})"
    elif defined(macosx):
        let
            pmset = execProcess("pmset -g batt | tail -n 1").split("\t")[1].split("; ")
            batteryCapacity = pmset[0]
            batteryStatus = pmset[1]
        result = &"{batteryCapacity} ({batteryStatus})"
    else:
        result = "Unknown"

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

proc getDisk*(mount: string): string =
    # Returns diskinfo for the mounting point
    proc getTotalDiskSpace(mountingPoint: cstring): cfloat {.importc, varargs, header: "getDisk.h".}
    proc getUsedDiskSpace(mountingPoint: cstring): cfloat {.importc, varargs, header: "getDisk.h".}

    let
        total = getTotalDiskSpace(mount.cstring).round().int()
        used = getUsedDiskSpace(mount.cstring).round().int()
        percentage = ((used / total) * 100).round().int()
    result = &"{used} / {total} GB ({percentage}%)"

proc getCpu*(): string =
    # Returns the cpu name
    let cacheFile = "cpu".toCachePath
    result = readCache(cacheFile)
    if result != "":
        return

    if defined(linux) or defined(bsd):
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
    elif defined(macosx):
        result = execProcess("sysctl -n machdep.cpu.brand_string").split("\n")[0]
    else:
        result = "Unknown"

    writeCache(cacheFile, result, initDuration(days=1))

proc getPkgManager(distroId: DistroId): string =
    for key in PKGMANAGERS.keys:
        if distroId.id == key:
            return PKGMANAGERS[key]

    for key in PKGMANAGERS.keys:
        if distroId.like == key:
            return PKGMANAGERS[key]

    return "Unknown"

proc getPackages*(distroId: DistroId = getDistroId()): string =
    # Returns the installed package count
    let cacheFile = "packages".toCachePath

    result = readCache(cacheFile)
    if result != "":
        return

    let pkgManager = getPkgManager(distroId)
    if pkgManager == "Unknown":
        return "Unknown"

    var foundPkgCmd = false
    for key in PKGCOUNTCOMMANDS.keys:
        if pkgManager == key:
            foundPkgCmd = true
            break
    if not foundPkgCmd:
        return "Unknown"

    let tmpFile = "packages.txt".toTmpPath
    let cmd: string = PKGCOUNTCOMMANDS[pkgManager] & " > " & tmpFile
    if execCmd(cmd) != 0:
        logError("Failed to fetch pkg count!")

    let count = readFile(tmpFile).strip()
    result = count & " [" & pkgManager & "]"
    writeCache(cacheFile, result, initDuration(hours=2))

proc cleanGpuName(raw: string): string =
    # Strip parenthesised technical details
    let parenIdx = raw.find('(')
    result = if parenIdx > 0: raw[0 ..< parenIdx].strip() else: raw.strip()

    # Normalise vendor prefixes so the name is consistent
    const prefixMap = [
        ("AMD Radeon",   "AMD Radeon"),
        ("NVIDIA",       "NVIDIA"),
        ("Intel",        "Intel"),
        # Mesa software renderers – collapse to a readable label
        ("llvmpipe",     "Software (llvmpipe)"),
        ("softpipe",     "Software (softpipe)"),
        ("D3D12",        "Software (D3D12)"),
    ]
    for (prefix, canon) in prefixMap:
        if result.toLowerAscii().startsWith(prefix.toLowerAscii()):
            # Re-attach the canonical prefix while preserving the model suffix
            if result.len > prefix.len:
                result = canon & result[prefix.len .. ^1]
            else:
                result = canon
            break

proc getVramMb(): int =
    # AMD / amdgpu – most reliable
    let drmBase = "/sys/class/drm"
    if dirExists(drmBase):
        for kind in ["card0", "card1", "card2"]:
            let p = drmBase / kind / "device" / "mem_info_vram_total"
            if fileExists(p):
                try:
                    let bytes = parseBiggestInt(readFile(p).strip())
                    if bytes > 0:
                        return int(bytes div (1024 * 1024))
                except: discard

    # NVIDIA – parse nvidia-smi
    try:
        let raw = execProcess("nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null").strip()
        if raw != "":
            return parseInt(raw.splitLines()[0].strip())
    except: discard

    # Intel / generic – drm resource file
    if dirExists(drmBase):
        for kind in ["card0", "card1", "card2"]:
            let p = drmBase / kind / "device" / "resource"
            if fileExists(p):
                try:
                    var best = 0
                    for line in readFile(p).splitLines():
                        let parts = line.splitWhitespace()
                        if parts.len >= 3:
                            let start = parseHexInt(parts[0])
                            let stop  = parseHexInt(parts[1])
                            let size  = int((stop - start + 1) div (1024 * 1024))
                            if size > best: best = size
                    if best > 0: return best
                except: discard

    return 0

proc formatVram(mb: int): string =
    # Round to the nearest sensible marketing size (e.g. 16376 MB → "16GB").
    if mb <= 0: return ""
    let gb = mb div 1024
    # Snap to the nearest power-of-two GB tier (2, 4, 6, 8, 12, 16, 24, 32 …)
    const tiers = [2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 48, 64, 80]
    for t in tiers:
        if gb <= t: return $t & "GB"
    return $gb & "GB"

proc getGpu*(): string =
    # Returns the gpu name
    let cacheFile = "gpu".toCachePath

    result = readCache(cacheFile)
    if result != "":
        return

    if defined(linux) or defined(bsd):
        let tmpFile = "glxinfo.txt".toTmpPath

        if execCmd("glxinfo -B > " & tmpFile & " 2>&1") != 0:
            if readFile(tmpFile).strip() == "Error: unable to open display":
                result = "Unknown"
            else: logError("Failed to fetch GPU!")
        else:
            var rawDevice    = "Unknown"
            var unifiedMemory = ""
            let glxinfo = readFile(tmpFile)
            for line in glxinfo.split('\n'):
                let split_line = line.strip().split(": ")
                if split_line[0] == "OpenGL renderer string":
                    rawDevice = split_line[1]
                elif split_line[0] == "Unified memory":
                    unifiedMemory = split_line[1]

                if rawDevice != "Unknown" and unifiedMemory != "":
                    break

            let device = cleanGpuName(rawDevice)

            var gputype = ""
            if unifiedMemory == "yes":
                gputype = "[integrated]"
            elif unifiedMemory == "no":
                gputype = "[dedicated]"
                # Fetch VRAM for discrete GPUs
                let vram = formatVram(getVramMb())
                if vram != "":
                    result = device & " " & vram & " " & gputype
                    writeCache(cacheFile, result, initDuration(days=1))
                    return

            result = device & (if gputype != "": " " & gputype else: "")

    elif defined(macosx):
        result = execProcess("system_profiler SPDisplaysDataType | grep 'Chipset Model'").split(": ")[1].split("\n")[0]
    else:
        result = "Unknown"

    writeCache(cacheFile, result, initDuration(days=1))

proc getWeather*(config: Config): string =
    # Returns current weather
    let cacheFile = "weather".toCachePath
    var location = "";
    if config.misc.contains("location"):
        location = config.misc["location"].getStr().replace(" ", "+")

    result = readCache(cacheFile)
    if result != "":
        return

    let tmpFile = "weather.txt".toTmpPath
    if execCmd("curl -s wttr.in/" & location & "?format=3 > " & tmpFile) != 0:
        logError("Failed to fetch weather!")

    result = readFile(tmpFile).strip()
    writeCache(cacheFile, result, initDuration(minutes=20))
