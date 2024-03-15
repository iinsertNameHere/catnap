import "catniplib/platform/fetch"
import "catniplib/drawing/render"
from "catniplib/common/defs" import CONFIGPATH
import "catniplib/common/config"
import os
from unicode import toLower
import strutils

# Debug code for execution time
when not defined release: 
    import times, strformat
    let t0 = epochTime()

# Load config
let cfg = LoadConfig(CONFIGPATH)

# Handle commandline args
var distroid = "nil"
var statname = "nil"
if paramCount() > 0:
    var idx = 1
    while paramCount() > (idx - 1):
        var param = paramStr(idx)

        # Help Argument
        if param == "-h" or param == "--help":
            echo "Usage:"
            echo "    catnip [options...]"
            echo ""
            echo "Options:"
            echo "    -h  --help                   Show help list"
            echo "    -d  --distroid <DistroId>    Force a DistroId"
            echo "    -g  --grep     <StatName>    Get the stats value"
            echo ""
            echo "StatNames:"
            echo "    username, hostname, uptime, distro, kernel, desktop, shell"
            echo ""
            echo "DistroIds:"
            echo "    " &  cfg.getAllDistros().join(", ")
            echo ""
            quit()

        # DistroId Argument
        elif param == "-d" or param == "--distroid":
            if paramCount() < 1:
                echo "ERROR: No DistroId was set with " & param
                quit(1)
            elif distroid != "nil":
                echo "ERROR: " & param & " can only be used once!"
                quit(1)
            elif statname != "nil":
                echo "ERROR: " & param & " and --grep/-g can't be used together!"
                quit(1)
            idx += 1
            distroid = paramStr(idx).toLower()

        # Grep Argument
        elif param == "-g" or param == "--grep":
            if paramCount() < 1:
                echo "ERROR: No StatName was set with " & param
                quit(1)
            elif statname != "nil":
                echo "ERROR: " & param & " can only be used once!"
                quit(1)
            elif distroid != "nil":
                echo "ERROR: " & param & " and --distroid/-d can't be used together!"
                quit(1)
            idx += 1
            statname = paramStr(idx).toLower()
        
        # Unknown Argument
        else:
            echo "ERROR: Unknown option '" & param & "'!"
            quit(1)

        idx += 1

if statname == "nil":
    # Get system info
    let fetchinfo = fetchSystemInfo(cfg, distroid)

    # Render system info
    echo ""
    Render(cfg, fetchinfo)
    echo ""

    # Debug code for execution time
    when not defined release: 
        let time = (epochTime() - t0).formatFloat(format = ffDecimal, precision = 3)
        echo &"Execution finished in {time}s"

else:
    let fetchinfo = fetchSystemInfo(cfg)
    case statname:
        of "username":
            echo fetchinfo.username
        of "hostname":
            echo fetchinfo.hostname
        of "uptime":
            echo fetchinfo.uptime
        of "distro":
            echo fetchinfo.distro
        of "kernel":
            echo fetchinfo.kernel
        of "desktop":
            echo fetchinfo.desktop
        of "shell":
            echo fetchinfo.shell
        else:
            echo "ERROR: Unknown StatName '" & statname & "'!"
            quit(1)
