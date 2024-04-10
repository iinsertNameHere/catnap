import "../terminal/logging"
from "definitions" import Config, STATNAMES, STATKEYS, Logo, DISTROSGPATH
from os import fileExists, getEnv, existsEnv
import strformat
import strutils
import parsetoml

# Chars that a alias can contain
const ALLOWED_NAME_CHARS = {'A' .. 'Z', 'a' .. 'z', '0' .. '9', '_'}
const VALID_TERMS = @["mlterm","yaft-256color","foot","foot-extra","st-256color","xterm","xterm-256color", "alacritty"]

proc isImageTerm(): bool =
    ## Returns true if terminal supports image mode
    var term = ""
    if getEnv("TERM_PROGRAM") != "":
        term = getEnv("TERM_PROGRAM")
    else: 
        term = getEnv("TERM")
    return (term in VALID_TERMS or "iTerm" in term or "WezTerm" in term or "mintty" in term or "kitty" in term)

proc LoadConfig*(path: string): Config =
    ## Lads a config file and validates it

    ### Validate the config file ###
    if not fileExists(path):
        logError(&"{path} - file not found!")

    if not fileExists(DISTROSGPATH):
        logError(&"{DISTROSGPATH} - file not found!")

    let tcfg = parsetoml.parseFile(path)
    let tdistros = parsetoml.parseFile(DISTROSGPATH)

    if not tcfg.contains("stats"):
        logError(&"{path} - missing 'stats'!")

    for statname in STATNAMES:
        if tcfg["stats"].contains(statname):
            for statkey in STATKEYS:
                if not tcfg["stats"][statname].contains(statkey):
                    logError(&"{path}:stats:{statname} - missing '{statkey}'!")
    if tcfg["stats"].contains("colors"):
        for statkey in STATKEYS & @["symbol"]:
            if not tcfg["stats"]["colors"].contains(statkey):
                logError(&"{path}:stats:colors - missing '{statkey}'!")

    if not tcfg.contains("misc"):
        logError(&"{path} - missing 'stats'!")
    if not tcfg["misc"].contains("layout"):
        logError(&"{path}:misc - missing 'layout'!")
    if not tcfg["misc"].contains("figletLogos"):
        logError(&"{path}:misc - missing 'figletLogos'!")
    if not tcfg["misc"]["figletLogos"].contains("enable"):
        logError(&"{path}:misc:figletLogos - missing 'enable'!")
    if not tcfg["misc"]["figletLogos"].contains("color"):
        logError(&"{path}:misc:figletLogos - missing 'color'!")
    if not tcfg["misc"]["figletLogos"].contains("font"):
        logError(&"{path}:misc:figletLogos - missing 'font'!")
    if not tcfg["misc"]["figletLogos"].contains("margin"):
        logError(&"{path}:misc:figletLogos - missing 'margin'!")
    if not tcfg["misc"].contains("imageMode"):
        logError(&"{path}:misc - missing 'imageMode'!")
    if not tcfg["misc"]["imageMode"].contains("enable"):
        logError(&"{path}:misc:imageMode - missing 'enable'!")
    if not tcfg["misc"]["imageMode"].contains("path"):
        logError(&"{path}:misc:imageMode - missing 'path'!")
    if not tcfg["misc"]["imageMode"].contains("scale"):
        logError(&"{path}:misc:imageMode - missing 'scale'!")
    if not tcfg["misc"]["imageMode"].contains("margin"):
        logError(&"{path}:misc:imageMode - missing 'font'!")

    if tcfg["misc"]["figletLogos"]["enable"].getBool() and tcfg["misc"]["imageMode"]["enable"].getBool():
        logError(&"{path}:misc - 'figletLogos' and 'imageMode' can't be used together!")

    # Check if terminal supports image mode
    if tcfg["misc"]["imageMode"]["enable"].getBool() and not isImageTerm():
        tcfg["misc"]["imageMode"]["enable"] = parsetoml.parseString(&"val = false")["val"]
        
    ### Fill out the result object ###
    result.file = path

    for distro in tdistros.getTable().keys:
        # Validate distroart objects
        if not tdistros[distro].contains("margin"):
            logError(&"{DISTROSGPATH}:{distro} - missing 'margin'!")

        var tmargin = tdistros[distro]["margin"].getElems
        if tmargin.len() < 3:
            var delta = 3 - tmargin.len()
            var s = (if delta > 1: "s" else: "")
            logError(&"{DISTROSGPATH}:{distro}:margin - missing {delta} value{s}!")

        if tmargin.len() > 3:
            var delta = tmargin.len() - 3
            var s = (if delta > 1: "s" else: "")
            logError(&"{DISTROSGPATH}:{distro}:margin - overflows by {delta} value{s}!")

        if not tdistros[distro].contains("art"):
            logError(&"{DISTROSGPATH}:{distro} - missing 'art'!")

        var tart = tdistros[distro]["art"].getElems
        if tart.len() < 1:
            logError(&"{DISTROSGPATH}:{distro}:art - is empty!")

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
                    logError(&"{DISTROSGPATH}:{distro} - alias '{name}' is already taken!")

                for c in name: # Check if name is a valid alias
                    if not (c in ALLOWED_NAME_CHARS):
                        logError(&"{DISTROSGPATH}:{distro} - '{name}' is not a valid alias!")

                result.distroart[name] = newLogo # Add alias to result

        newLogo.isAlias = false

        result.distroart[distro] = newLogo # Add distroart obj to result

    if not result.distroart.contains("default"): # Validate that default alias exists
        logError(&"{DISTROSGPATH} - missing 'default'!")

    result.stats = tcfg["stats"]
    result.misc = tcfg["misc"]

proc getAllDistros*(cfg: Config): seq[string] =
    ## Function that returns all keys of distroart Table
    let distroart = cfg.distroart
    for k in distroart.keys:
        if not distroart[k].isAlias:
            result.add(k)
