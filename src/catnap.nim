import std/wordwrap
import strutils
import strformat
import tables
import os

from "common/definitions" import STATNAMES, CACHEPATH, TEMPPATH
from "common/version"     import VERSION
import "common/logging"
import "common/cli"
from "config/types" import Config
import "config/config"
import "system/fetch"
import "system/probe"
import "rendering/render"

when not defined release:
    import times
    let t0 = epochTime()

proc printHelp(cfg: Config) =
    var disk_statnames: seq[string]
    for i in 0 ..< probe.getMounts().len:
        disk_statnames.add("disk_" & $i)

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
    echo ""
    echo "    -m  --margin               <Margin>       Overwrite margin value for the displayed logo (Example: 1,2,3)"
    echo "    -l  --layout               <Layout>       Overwrite layout config value [Inline,ArtOnTop,StatsOnTop]"
    echo ""
    echo "StatNames:"
    echo "    " & (STATNAMES & @["disks"] & disk_statnames).join(", ").wrapWords(80).replace("\n", "\n    ")
    echo ""
    echo "DistroIds:"
    echo "    " & cfg.getAllDistros().join(", ").wrapWords(80).replace("\n", "\n    ")
    echo ""

let args = parseArgs()

if args.version:
    echo "Catnap v" & VERSION
    quit(0)

if args.noCache and dirExists(CACHEPATH): removeDir(CACHEPATH)
if not dirExists(CACHEPATH): createDir(CACHEPATH)
if not dirExists(TEMPPATH):  createDir(TEMPPATH)

var cfg = LoadConfig(args.cfgPath)

if args.help:     printHelp(cfg); quit(0)
if args.hasError: quit(1)

if args.statname == "":
    if args.margin.len == 3:
        for key in cfg.distroart.keys:
            cfg.distroart[key].margin = [args.margin[0], args.margin[1], args.margin[2]]

    if args.layout != "":
        cfg.misc.layout = args.layout

    let fetchinfo = fetchSystemInfo(cfg, args.distroid)
    echo ""
    Render(cfg, fetchinfo)
    echo ""
else:
    if args.statname == "disks":
        for i, p in probe.getMounts():
            echo "disk_" & $i & ": " & p
        quit(0)

    let fetchinfo = fetchSystemInfo(cfg)
    if not fetchinfo.list.contains(args.statname):
        logError(&"Unknown StatName '{args.statname}'!")
    echo fetchinfo.list[args.statname]()

when not defined release:
    let time = (epochTime() - t0).formatFloat(format = ffDecimal, precision = 3)
    echo &"Execution finished in {time}s"
