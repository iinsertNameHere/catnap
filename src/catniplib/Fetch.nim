import "fetch/linux" as platform
from "common/Definitions" import FetchInfo, CONFIGPATH
import "common/Config"
import json

proc FetchSystemInfo*(distroId: string = "nil"): FetchInfo =
    result.username = platform.getUser()
    result.hostname = platform.getHostname()
    result.distro   = platform.getDistro()
    result.uptime   = platform.getUptime()
    result.kernel   = platform.getKernel()
    result.desktop  = platform.getDesktop()
    result.shell    = platform.getShell()
    result.distroId = platform.getDistroId()

    var distroId = (if distroId != "nil": distroId else: result.distroId.id)

    let config = Config.LoadConfig(CONFIGPATH)

    if config.distroart{distroId} == nil:
        distroId = result.distroId.like
        if config.distroart{distroId} == nil:
            distroId = "default"

    let jalias = config.distroart[distroId]{"alias"} 
    if jalias != nil:
        distroId = jalias.getStr()
        if config.distroart{distroId} == nil:
            distroId = "default"

    let jmargin = config.distroart[distroId]["margin"]
    result.logo.margin = [jmargin[0].getInt(), jmargin[1].getInt(), jmargin[2].getInt()]
    for line in config.distroart[distroId]["art"]:
        result.logo.art.add(line.getStr())