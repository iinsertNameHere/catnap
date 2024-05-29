import osproc
import strformat
import strutils

from "../global/definitions" import FetchInfo, Config, toTmpPath
import "../terminal/logging"
import parsetoml
import "probe"

proc fetchSystemInfo*(config: Config, distroId: string = "nil"): FetchInfo =
    result.distroId = probe.getDistroId()
    result.list["username"] = probe.getUser()
    result.list["hostname"] = probe.getHostname()
    result.list["distro"]   = probe.getDistro()
    result.list["uptime"]   = probe.getUptime()
    result.list["kernel"]   = probe.getKernel()
    result.list["desktop"]  = probe.getDesktop()
    result.list["terminal"] = probe.getTerminal()
    result.list["shell"]    = probe.getShell()
    result.list["memory"]   = probe.getMemory(true)
    result.list["cpu"]      = probe.getCpu()
    result.list["gpu"]      = probe.getGpu()
    result.list["packages"] = probe.getPackages(result.distroId)
    result.list["weather"]  = probe.getWeather()

    # Add a disk stat for all mounts
    let mounts = probe.getMounts()
    if mounts.len > 0:
        var index = 0
        for mount in mounts:
            let name = "disk_" & $index
            result.list[name] = probe.getDisk(mount)
            result.disk_statnames.add(name)
            index += 1
    else:
        result.list["disk_0"] = probe.getDisk("disk_0")
        result.disk_statnames.add("disk_0")

    var distroId = (if distroId != "nil": distroId else: result.distroId.id)
    let figletLogos = config.misc["figletLogos"]

    if not figletLogos["enable"].getBool(): # Get logo from config file
        if not config.distroart.contains(distroId):
            distroId = result.distroId.like
            if not config.distroart.contains(distroId):
                distroId = "default"

        result.logo = config.distroart[distroId]

    else: # Generate logo using figlet
        let figletFont = figletLogos["font"]
        let tmpFile = "figlet_art.txt".toTmpPath 

        if execCmd(&"figlet -f {figletFont} '{distroId}' > {tmpFile}") != 0:
            logError("Failed to execute 'figlet'!")
        let artLines = readFile(tmpFile).split('\n')
        let tmargin = figletLogos["margin"]
        result.logo.margin = [tmargin[0].getInt(), tmargin[1].getInt(), tmargin[2].getInt()]
        for line in artLines:
            if line != "":
                result.logo.art.add(figletLogos["color"].getStr() & line)
