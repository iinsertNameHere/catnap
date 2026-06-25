import os
import strformat
import tables
import "../common/logging"
from "../common/definitions" import CONFIGPATH, GLOBALCONFIGPATH
from "types" import Config
from "dsl/config" import loadDslConfig, dslToConfig

proc LoadConfig*(cfgPath: string): Config =
    var configPath: string
    if not fileExists(cfgPath):
        if fileExists(GLOBALCONFIGPATH):
            configPath = GLOBALCONFIGPATH
        else:
            logError(&"{cfgPath} - file not found!")
            return
    else:
        configPath = cfgPath

    let src     = readFile(configPath)
    let baseDir = parentDir(configPath)
    let output  = loadDslConfig(src, baseDir)
    result      = dslToConfig(output, configPath)

proc getAllDistros*(cfg: Config): seq[string] =
    for k in cfg.distroart.keys:
        result.add(k)
