import osproc
import strformat
import strutils

from "../global/definitions" import FetchInfo, Config
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
    result.list["disk"]     = probe.getDisk()
    result.list["cpu"]      = probe.getCpu()
    result.list["packages"] = probe.getPackages(result.distroId)

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
        if execCmd(&"figlet -f {figletFont} '{distroId}' > /tmp/catnip_figlet_art.txt") != 0:
            echo "ERROR: Failed to execute 'figlet'!"
            quit(1)
        let artLines = readFile("/tmp/catnip_figlet_art.txt").split('\n')
        let tmargin = figletLogos["margin"]
        result.logo.margin = [tmargin[0].getInt(), tmargin[1].getInt(), tmargin[2].getInt()]
        for line in artLines:
            if line != "":
                result.logo.art.add(figletLogos["color"].getStr() & line)
