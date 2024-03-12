from "common/defs" import FetchInfo, CONFIGPATH
import "common/config"
import "common/toml"
import "platform"
import osproc
import strformat
import strutils

proc fetchSystemInfo*(distroId: string = "nil"): FetchInfo =
    result.username = platform.getUser()
    result.hostname = platform.getHostname()
    result.distro   = platform.getDistro()
    result.uptime   = platform.getUptime()
    result.kernel   = platform.getKernel()
    result.desktop  = platform.getDesktop()
    result.shell    = platform.getShell()
    result.distroId = platform.getDistroId()

    var distroId = (if distroId != "nil": distroId else: result.distroId.id)

    let config = LoadConfig(CONFIGPATH)
    let figletLogos = config.misc["figletLogos"]

    if not figletLogos["enable"].getBool(): # Get logo from config file
        if not config.distroart.contains(distroId):
            distroId = result.distroId.like
            if not config.distroart.contains(distroId):
                distroId = "default"

        
        if config.distroart[distroId].contains("alias"):
            let talias = config.distroart[distroId]["alias"]
            distroId = talias.getStr()
            if not config.distroart.contains(distroId):
                distroId = "default"

        let tmargin = config.distroart[distroId]["margin"]
        result.logo.margin = [tmargin[0].getInt(), tmargin[1].getInt(), tmargin[2].getInt()]
        for line in config.distroart[distroId]["art"].getElems:
            result.logo.art.add(line.getStr())
    else: # Generate logo using figlet'
        when defined linux:
            discard execCmd(&"figlet -f slant '{distroId}' > /tmp/catnip_figlet_art.txt")
            let artLines = readFile("/tmp/catnip_figlet_art.txt").split('\n')
            let tmargin = figletLogos["margin"]
            result.logo.margin = [tmargin[0].getInt(), tmargin[1].getInt(), tmargin[2].getInt()]
            for line in artLines:
                if line != "":
                    result.logo.art.add(figletLogos["color"].getStr() & line)

        when defined windows:
            echo &"ERROR: {CONFIGPATH}:misc:figletLogos - Not supported on windows yet"
            exit(0)
