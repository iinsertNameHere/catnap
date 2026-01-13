import "../terminal/logging"
from "definitions" import Config, STATNAMES, STATKEYS, Logo, DISTROSPATH, GLOBALCONFIGPATH, GLOBALDISTROSPATH
from os import fileExists, getEnv, existsEnv
import strformat
import strutils
import parsetoml

# Chars that a alias can contain
const ALLOWED_NAME_CHARS = {'A' .. 'Z', 'a' .. 'z', '0' .. '9', '_'}

proc LoadConfig*(cfgPath: string, dstPath: string): Config =
    # Lads a config file and validates it

    # Validate the config file and handle global config
    var configPath: string
    if not fileExists(cfgPath):
        if fileExists(GLOBALCONFIGPATH):
            configPath = GLOBALCONFIGPATH
        else:
            logError(&"{cfgPath} - file not found!")
    else:
        configPath = cfgPath
        
    
    # Validate the art file and handle global art file
    var distrosPath: string
    if not fileExists(dstPath):
        if fileExists(GLOBALDISTROSPATH):
            distrosPath = GLOBALDISTROSPATH
        else:
            logError(&"{dstPath} - file not found!")
    else:
        distrosPath = dstPath

    let tcfg = parsetoml.parseFile(configPath)
    let tdistros = parsetoml.parseFile(distrosPath)
    
    # Error out if stats missing
    if not tcfg.contains("stats"):
        logError(&"{cfgPath} - missing 'stats'!")

    for statname in STATNAMES:
        if tcfg["stats"].contains(statname):
            for statkey in STATKEYS:
                if not tcfg["stats"][statname].contains(statkey):
                    logError(&"{cfgPath}:stats:{statname} - missing '{statkey}'!")
    if tcfg["stats"].contains("colors"):
        for statkey in STATKEYS & @["symbol"]:
            if not tcfg["stats"]["colors"].contains(statkey):
                logError(&"{cfgPath}:stats:colors - missing '{statkey}'!")

    if not tcfg.contains("misc"):
        logError(&"{cfgPath} - missing 'stats'!")
    if not tcfg["misc"].contains("layout"):
        logError(&"{cfgPath}:misc - missing 'layout'!")
        
    # Fill out the result object
    result.configFile = cfgPath
    result.distrosFile = dstPath

    for distro in tdistros.getTable().keys:
        # Validate distroart objects
        if not tdistros[distro].contains("margin"):
            logError(&"{dstPath}:{distro} - missing 'margin'!")

        var tmargin = tdistros[distro]["margin"].getElems
        if tmargin.len() < 3:
            var delta = 3 - tmargin.len()
            var s = (if delta > 1: "s" else: "")
            logError(&"{dstPath}:{distro}:margin - missing {delta} value{s}!")

        if tmargin.len() > 3:
            var delta = tmargin.len() - 3
            var s = (if delta > 1: "s" else: "")
            logError(&"{dstPath}:{distro}:margin - overflows by {delta} value{s}!")

        if not tdistros[distro].contains("art"):
            logError(&"{dstPath}:{distro} - missing 'art'!")

        var tart = tdistros[distro]["art"].getElems
        if tart.len() < 1:
            logError(&"{dstPath}:{distro}:art - is empty!")

        # Generate Logo Objects
        var newLogo: Logo
        newLogo.margin = [tmargin[0].getInt(), tmargin[1].getInt(), tmargin[2].getInt()]
        for line in tart:
            newLogo.art.add(line.getStr())

        # Inflate distroart table with alias if exists
        if tdistros[distro].contains("alias"):
            let raw_alias_list = tdistros[distro]["alias"].getStr().split(",")
            var alias_list: seq[string]
            for alias in raw_alias_list:
                alias_list.add(alias.strip())

            newLogo.isAlias = true

            for name in alias_list:
                if result.distroart.hasKey(name) or name == distro:
                    logError(&"{dstPath}:{distro} - alias '{name}' is already taken!")

                for c in name: # Check if name is a valid alias
                    if not (c in ALLOWED_NAME_CHARS):
                        logError(&"{dstPath}:{distro} - '{name}' is not a valid alias!")

                result.distroart[name] = newLogo # Add alias to result

        newLogo.isAlias = false

        result.distroart[distro] = newLogo # Add distroart obj to result

    if not result.distroart.contains("default"): # Validate that default alias exists
        logError(&"{dstPath} - missing 'default'!")

    result.stats = tcfg["stats"]
    result.misc = tcfg["misc"]

proc getAllDistros*(cfg: Config): seq[string] =
    # Function that returns all keys of distroart Table
    let distroart = cfg.distroart
    for k in distroart.keys:
        if not distroart[k].isAlias:
            result.add(k)
