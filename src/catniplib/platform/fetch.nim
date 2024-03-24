import osproc
import strformat
import strutils

from "../global/definitions" import FetchInfo, Config
import parsetoml
import "probe"

proc fetchSystemInfo*(config: Config, distroId: string = "nil"): FetchInfo =
    result.username = probe.getUser()
    result.hostname = probe.getHostname()
    result.distro   = probe.getDistro()
    result.uptime   = probe.getUptime()
    result.kernel   = probe.getKernel()
    result.desktop  = probe.getDesktop()
    result.terminal = probe.getTerminal()
    result.shell    = probe.getShell()
    result.memory   = probe.getMemory(true)
    result.disk     = probe.getDisk()
    result.distroId = probe.getDistroId()

    var distroId = (if distroId != "nil": distroId else: result.distroId.id)
    let figletLogos = config.misc["figletLogos"]

    if not figletLogos["enable"].getBool(): # Get logo from config file
        if not config.distroart.contains(distroId):
            distroId = result.distroId.like
            if not config.distroart.contains(distroId):
                distroId = "default"

        result.logo = config.distroart[distroId]

    else: # Generate logo using figlet
        when defined linux:
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

        when defined windows:
            logError(&"{config.file}:misc:figletLogos - Not supported on windows yet")
            exit(0)
