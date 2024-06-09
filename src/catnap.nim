import "catnaplib/platform/fetch"
import "catnaplib/drawing/render"
from "catnaplib/global/definitions" import CONFIGPATH, DISTROSPATH, Config, STATNAMES, CACHEPATH
import "catnaplib/global/config"
import "catnaplib/terminal/logging"
import parsetoml
import os
from unicode import toLower
import strutils
import strformat
import std/wordwrap
import "catnaplib/platform/probe"
from "catnaplib/global/currentcommit" import CURRENTCOMMIT

# Debug code for execution time
when not defined release:
    import times
    let t0 = epochTime()

# Help text
proc printHelp(cfg: Config) =
    let mounts_len = probe.getMounts().len
    var disk_statnames: seq[string]
    var count = 0
    while count < mounts_len:
        disk_statnames.add("disk_" & $count)
        count += 1

    echo "Usage:"
    echo "    catnap [options] [arguments]"
    echo ""
    echo "Options:"
    echo "    -h  --help                                Show help list"
    echo "    -v  --version                             Shows info about the version"
    echo "    -d  --distroid             <DistroId>     Set which DistroId to use"
    echo "    -g  --grep                 <StatName>     Get the stats value"
    echo "    -n  --no-cache                            Clears the cache before execution"
    echo "    -c  --config               <ConfigPath>   Uses a custom location for the config file"
    echo "    -a  --art                  <DistrosPath>  Uses a custom location for the distros file"
    echo ""
    echo "    -m  --margin               <Margin>       Overwrite margin value for the displayed logo (Example: 1,2,3)"
    echo "    -l  --layout               <Layout>       Overwrite layout config value [Inline,LogoOnTop,StatsOnTop]"
    echo ""
    echo "    -fe --figletLogos.enable   <on/off>       Overwrite figletLogos mode"
    echo "    -fm --figletLogos.margin   <Margin>       Overwrite figletLogos margin (Example: 1,2,3)"
    echo "    -ff --figletLogos.font     <Font>         Overwrite figletLogos font"
    echo ""
    echo "StatNames:"
    echo "    " & (STATNAMES & @["disks"] & disk_statnames).join(", ").wrapWords(80).replace("\n", "\n    ")
    echo ""
    echo "DistroIds:"
    echo "    " &  cfg.getAllDistros().join(", ").wrapWords(80).replace("\n", "\n    ")
    echo ""
    quit()

# Handle commandline args
var distroid = "nil"
var statname = "nil"
var figletLogos_enabled = "nil"
var figletLogos_margin: seq[int]
var figletLogos_font = "nil"
var layout = "nil"
var margin: seq[int]
var cfgPath = CONFIGPATH
var dstPath = DISTROSPATH
var help = false
var error = false

if paramCount() > 0:
    var idx = 1
    while paramCount() > (idx - 1):
        var param = paramStr(idx)

        # Version Argument
        if param == "-v" or param == "--version":
            echo "Commit " & CURRENTCOMMIT
            quit()

        # Config Argument
        elif param == "-c" or param == "--config":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            idx += 1
            cfgPath = paramStr(idx)

        # Art Argument
        elif param == "-a" or param == "--art":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            idx += 1
            dstPath = paramStr(idx)

        # Help Argument
        elif param == "-h" or param == "--help":
            help = true

        # DistroId Argument
        elif param == "-d" or param == "--distroid":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif distroid != "nil":
                logError(&"{param} - Can only be used once!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"{param} - Can't be used together with: -g/--grep", false)
                error = true
                idx += 1
                continue
            idx += 1
            distroid = paramStr(idx).toLower()

        # No Cache Argument
        elif param == "-n" or param == "--no-cache":
            if dirExists(CACHEPATH): removeDir(CACHEPATH)

        # Grep Argument
        elif param == "-g" or param == "--grep":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"{param} - Can only be used once!", false)
                error = true
                idx += 1
                continue
            elif distroid != "nil":
                logError(&"{param} - Can't be used together with: -d/--distroid", false)
                error = true
                idx += 1
                continue
            idx += 1
            statname = paramStr(idx).toLower()

        # Margin Argument
        elif param == "-m" or param == "--margin":
            if paramCount() - idx < 1:
                logError(&"{param} - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"'{param}' - Can't be used together with: -g/--grep", false)
                error = true
                idx += 1
                continue
            elif figletLogos_margin.len > 0:
                logError(&"'{param}' - Can only be used once!", false)
                error = true
                idx += 1
                continue

            idx += 1
            let margin_list = paramStr(idx).split(",")
            if margin_list.len < 3:
                logError(&"'{param}' - Value dose not match format!", false)
                error = true
                idx += 1
                continue

            for idx in countup(0, 2):
                let num = margin_list[idx].strip()
                var parsed_num: int

                try:
                    parsed_num = parseInt(num)
                except:
                    logError(&"'{param}' - Value[{idx}] is not a number!", false)
                    error = true
                    break

                margin.add(parsed_num)

        # Layout Argument
        elif param == "-l" or param == "--layout":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"{param} - Can't be used together with: -g/--grep", false)
                error = true
                idx += 1
                continue
            elif layout != "nil":
                logError(&"{param} - Can only be used once!", false)
                error = true
                idx += 1
                continue

            idx += 1
            layout = paramStr(idx)

        # FigletLogos enabled Argument
        elif param == "-fe" or param == "--figletLogos.enabled":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"{param} - Can't be used together with: -g/--grep", false)
                error = true
                idx += 1
                continue
            elif figletLogos_enabled != "nil":
                logError(&"{param} - Can only be used once!", false)
                error = true
                idx += 1
                continue

            idx += 1
            figletLogos_enabled = paramStr(idx).toLower()
            if figletLogos_enabled != "on" and figletLogos_enabled != "off":
                logError(&"{param} - Value is not 'on' or 'off'!", false)
                error = true
                idx += 1
                continue

        # FigletLogos margin Argument
        elif param == "-fm" or param == "--figletLogos.margin":
            if paramCount() - idx < 1:
                logError(&"{param} - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"'{param}' - Can't be used together with: -g/--grep", false)
                error = true
                idx += 1
                continue
            elif figletLogos_margin.len > 0:
                logError(&"'{param}' - Can only be used once!", false)
                error = true
                idx += 1
                continue

            idx += 1
            let margin_list = paramStr(idx).split(",")
            if margin_list.len < 3:
                logError(&"'{param}' - Value dose not match format!", false)
                error = true
                idx += 1
                continue

            for idx in countup(0, 2):
                let num = margin_list[idx].strip()
                var parsed_num: int

                try:
                    parsed_num = parseInt(num)
                except:
                    logError(&"'{param}' - Value[{idx}] is not a number!", false)
                    error = true
                    break

                figletLogos_margin.add(parsed_num)


        # FigletLogos font Argument
        elif param == "-ff" or param == "--figletLogos.font":
            if paramCount() - idx < 1:
                logError(&"'{param}' - No Value was specified!", false)
                error = true
                idx += 1
                continue
            elif statname != "nil":
                logError(&"'{param}' - Can't be used together with: -g/--grep", false)
                error = true
                idx += 1
                continue
            elif figletLogos_font != "nil":
                logError(&"'{param}' - Can only be used once!", false)
                error = true
                idx += 1
                continue

            idx += 1
            figletLogos_font = paramStr(idx)

        # Unknown Argument
        else:
            logError(&"Unknown option '{param}'!", false)
            error = true
            idx += 1
            continue

        idx += 1


# Create tmp folder
if not dirExists(CACHEPATH):
    createDir(CACHEPATH)

# Getting config
var cfg = LoadConfig(cfgPath, dstPath)

# Handle argument errors and help
if help: printHelp(cfg)
if error: quit(1)
elif help: quit(0)

if statname == "nil":
    # Handle margin overwrite
    if margin.len == 3:
        for key in cfg.distroart.keys:
            cfg.distroart[key].margin = [margin[0], margin[1], margin[2]]

    # Handle layout overwrite
    if layout != "nil":
        cfg.misc["layout"] = parseString(&"val = '{layout}'")["val"]

    # Handle figletLogos overwrites
    if figletLogos_enabled != "nil":
        let onoff = if figletLogos_enabled == "on": "true" else: "false"
        cfg.misc["figletLogos"]["enable"] = parseString(&"val = {onoff}")["val"]
    if figletLogos_margin.len == 3:
        let fmargin = &"[{figletLogos_margin[0]},{figletLogos_margin[1]},{figletLogos_margin[2]},]"
        cfg.misc["figletLogos"]["margin"] = parseString(&"val = {fmargin}")["val"]
    if figletLogos_font != "nil":
        cfg.misc["figletLogos"]["font"] = parseString(&"val = '{figletLogos_font}'")["val"]

    # Get system info
    let fetchinfo = fetchSystemInfo(cfg, distroid)

    # Render system info
    echo ""
    Render(cfg, fetchinfo)
    echo ""

else:
    if statname == "disks":
        var count = 0
        for p in probe.getMounts():
            echo "disk_" & $count & ": " & p
            count += 1
        quit()
    else:
        let fetchinfo = fetchSystemInfo(cfg)
        
        if not fetchinfo.list.contains(statname):
            logError(&"Unknown StatName '{statname}'!")
        
        echo fetchinfo.list[statname]()

# Debug code for execution time
when not defined release:
    let time = (epochTime() - t0).formatFloat(format = ffDecimal, precision = 3)
    echo &"Execution finished in {time}s"
