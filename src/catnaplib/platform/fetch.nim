import osproc
import strformat
import strutils

from "../global/definitions" import FetchInfo, Config, toTmpPath
import "../terminal/logging"
import parsetoml
import "probe"

proc fetchSystemInfo*(config: Config, distroId: string = "nil"): FetchInfo =
    result.distroId = probe.getDistroId()
    result.list["username"] = proc(): string = return probe.getUser()
    result.list["hostname"] = proc(): string = return probe.getHostname()
    result.list["distro"]   = proc(): string = return probe.getDistro()
    result.list["uptime"]   = proc(): string = return probe.getUptime()
    result.list["kernel"]   = proc(): string = return probe.getKernel()
    result.list["desktop"]  = proc(): string = return probe.getDesktop()
    result.list["terminal"] = proc(): string = return probe.getTerminal()
    result.list["shell"]    = proc(): string = return probe.getShell()
    result.list["memory"]   = proc(): string = return probe.getMemory()
    result.list["cpu"]      = proc(): string = return probe.getCpu()
    result.list["gpu"]      = proc(): string = return probe.getGpu()
    result.list["packages"] = proc(): string = return probe.getPackages()
    result.list["weather"]  = proc(): string = return probe.getWeather()

    # Add a disk stat for all mounts
    let mounts = probe.getMounts()
    if mounts.len > 0:
        var index = 0
        for mount in mounts:
            let name = "disk_" & $index
            
            var refmount: ref string
            new(refmount)
            refmount[] = mount

            result.list[name] = proc(): string = return probe.getDisk(refmount)
            result.disk_statnames.add(name)
            index += 1
    else:
        var refmount: ref string
        new(refmount)
        refmount[] = "disk_0"

        result.list["disk_0"] = proc(): string = return probe.getDisk(refmount)
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
