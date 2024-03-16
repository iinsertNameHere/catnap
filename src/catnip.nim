import "catniplib/platform/fetch"
import "catniplib/drawing/render"
from "catniplib/common/defs" import CONFIGPATH, Config
import "catniplib/common/config"
import "catniplib/common/logging"
import os
from unicode import toLower
import strutils
import strformat
import std/wordwrap

# Debug code for execution time
when not defined release:
    import times
    let t0 = epochTime()

#Margin must be set here in order to be before the help argument.
var margin = 80

proc printHelp(cfg: Config) =
    echo "Usage:"
    echo "    catnip [options...]"
    echo ""
    echo "Options:"
    echo "    -h  --help                   Show help list"
    echo "    -d  --distroid <DistroId>    Force a DistroId"
    echo "    -g  --grep     <StatName>    Get the stats value"
    echo "    -c  --config   <ConfigDir>   Uses a custom location for the config file"
    echo "    -m  --margin   <MarginSize>  Uses a custom margin size for DistroId."
    echo ""
    echo "StatNames:"
    echo "    username, hostname, uptime, distro, kernel, desktop, shell"
    echo ""
    echo "DistroIds:"
    echo "    " &  cfg.getAllDistros().join(", ").wrapWords(margin).replace("\n", "\n    ")
    echo ""
    quit()

# Handle commandline args
var distroid = "nil"
var statname = "nil"
var cfgPath = CONFIGPATH
var help = false
var error = false

if paramCount() > 0:
    var idx = 1
    while paramCount() > (idx - 1):
        var param = paramStr(idx)
        
        # Margin Argument
        if param == "-m" or param == "--margin":
            if paramCount() - idx < 1:
                logError("No margin size specificed.", false)
                error = true
                idx += 1
                continue
            idx += 1
            margin = parseInt(paramStr(idx))
        
        # Config Argument
        if param == "-c" or param == "--config":
            if paramCount() - idx < 1:
                logError("No ConfigDir was specified.", false)
                error = true
                idx += 1
                continue
            idx += 1
            cfgPath = paramStr(idx)

        # Help Argument
        elif param == "-h" or param == "--help":
            help = true

        # DistroId Argument
        elif param == "-d" or param == "--distroid":
            if paramCount() - idx < 1:
                logError("No DistroId was specified.", false)
                error = true
                idx += 1
                continue
            elif distroid != "nil":
                logError(&"{param} can only be used once!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"{param} and --grep/-g can't be used together!", false)
                error = true
                idx += 1
                continue
            idx += 1
            distroid = paramStr(idx).toLower()

        # Grep Argument
        elif param == "-g" or param == "--grep":
            if paramCount() - idx < 1:
                logError("No StatName was specified.", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"{param} can only be used once!", false)
                error = true
                idx += 1
                continue
            elif distroid != "nil":
                logError(&"{param} and --distroid/-d can't be used together!", false)
                error = true
                idx += 1
                continue
            idx += 1
            statname = paramStr(idx).toLower()

        # Unknown Argument
        else:
            logError(&"Unknown option '{param}'!", false)
            error = true
            idx += 1
            continue

        idx += 1

let cfg = LoadConfig(cfgPath)

# Handle argument errors and help
if help: printHelp(cfg)
if error: quit(1)
elif help: quit(0)

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
            logError(&"Unknown StatName '{statname}'!")
