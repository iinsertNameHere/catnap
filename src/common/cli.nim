import os
import strutils
import strformat
from unicode import toLower

from "definitions" import CONFIGPATH
import "logging"

type Args* = object
    cfgPath*:  string
    distroid*: string
    statname*: string
    layout*:   string
    margin*:   seq[int]
    help*:     bool
    version*:  bool
    noCache*:  bool
    hasError*: bool

proc parseArgs*(): Args =
    result.cfgPath = CONFIGPATH

    var idx = 1
    while idx <= paramCount():
        let param = paramStr(idx)

        case param
        of "-v", "--version":
            result.version = true

        of "-h", "--help":
            result.help = true

        of "-n", "--no-cache":
            result.noCache = true

        of "-c", "--config":
            if idx >= paramCount():
                logError(&"'{param}' - No value was specified!", false)
                result.hasError = true
            else:
                idx += 1
                result.cfgPath = paramStr(idx)

        of "-d", "--distroid":
            if idx >= paramCount():
                logError(&"'{param}' - No value was specified!", false)
                result.hasError = true
            elif result.distroid != "":
                logError(&"'{param}' - Can only be used once!", false)
                result.hasError = true
            elif result.statname != "":
                logError(&"'{param}' - Can't be used together with: -g/--grep", false)
                result.hasError = true
            else:
                idx += 1
                result.distroid = paramStr(idx).toLower()

        of "-g", "--grep":
            if idx >= paramCount():
                logError(&"'{param}' - No value was specified!", false)
                result.hasError = true
            elif result.statname != "":
                logError(&"'{param}' - Can only be used once!", false)
                result.hasError = true
            elif result.distroid != "":
                logError(&"'{param}' - Can't be used together with: -d/--distroid", false)
                result.hasError = true
            else:
                idx += 1
                result.statname = paramStr(idx).toLower()

        of "-m", "--margin":
            if idx >= paramCount():
                logError(&"'{param}' - No value was specified!", false)
                result.hasError = true
            elif result.statname != "":
                logError(&"'{param}' - Can't be used together with: -g/--grep", false)
                result.hasError = true
            else:
                idx += 1
                let parts = paramStr(idx).split(",")
                if parts.len < 3:
                    logError(&"'{param}' - Value does not match format!", false)
                    result.hasError = true
                else:
                    for i in 0 ..< 3:
                        try:
                            result.margin.add(parseInt(parts[i].strip()))
                        except ValueError:
                            logError(&"'{param}' - Value[{i}] is not a number!", false)
                            result.hasError = true
                            break

        of "-l", "--layout":
            if idx >= paramCount():
                logError(&"'{param}' - No value was specified!", false)
                result.hasError = true
            elif result.statname != "":
                logError(&"'{param}' - Can't be used together with: -g/--grep", false)
                result.hasError = true
            elif result.layout != "":
                logError(&"'{param}' - Can only be used once!", false)
                result.hasError = true
            else:
                idx += 1
                result.layout = paramStr(idx)

        else:
            logError(&"Unknown option '{param}'!", false)
            result.hasError = true

        idx += 1
