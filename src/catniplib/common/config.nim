import "toml"
from "defs" import Config, STATNAMES, STATKEYS, Logo
from os import fileExists
import strformat
import strutils

# Chars that a alias can contain
const ALLOWED_NAME_CHARS = {'A' .. 'Z', 'a' .. 'z', '0' .. '9', '_'}

proc LoadConfig*(path: string): Config =
    ## Lads a config file and validates it

    ### Validate the config file ###
    if not fileExists(path):
        echo &"ERROR: {path} - file not found!"
        quit(1)

    let tcfg = toml.parseFile(path)
    
    if not tcfg.contains("stats"):
        echo &"ERROR: {path} - missing 'stats'!"
        quit(1)

    for statname in STATNAMES:
        if tcfg["stats"].contains(statname):
            for statkey in STATKEYS:
                if not tcfg["stats"][statname].contains(statkey):
                    echo &"ERROR: {path}:stats:" & statname & " - missing '" & statkey & "'!"
                    quit(1)  
    if tcfg["stats"].contains("colors"):
        for statkey in STATKEYS & @["symbol"]:
            if not tcfg["stats"]["colors"].contains(statkey):
                echo &"ERROR: {path}:stats:colors - missing '" & statkey & "'!"
                quit(1)

    if not tcfg.contains("distroart"):
        echo &"ERROR: {path} - missing 'distroart'!"
        quit(1)

    if not tcfg.contains("misc"):
        echo &"ERROR: {path} - missing 'stats'!"
        quit(1)

    if not tcfg["misc"].contains("layout"):
        echo &"ERROR: {path}:misc - missing 'layout'!"
        quit(1)

    if not tcfg["misc"].contains("figletLogos"):
        echo &"ERROR: {path}:misc - missing 'figletLogos'!"
        quit(1)

    if not tcfg["misc"]["figletLogos"].contains("enable"):
        echo &"ERROR: {path}:misc:figletLogos - missing 'enable'!"
        quit(1)
    
    if not tcfg["misc"]["figletLogos"].contains("color"):
        echo &"ERROR: {path}:misc:figletLogos - missing 'color'!"
        quit(1)

    if not tcfg["misc"]["figletLogos"].contains("font"):
        echo &"ERROR: {path}:misc:figletLogos - missing 'font'!"
        quit(1)

    if not tcfg["misc"]["figletLogos"].contains("margin"):
        echo &"ERROR: {path}:misc:figletLogos - missing 'margin'!"
        quit(1)
    
    ### Fill out the result object ###
    result.file = path

    for distro in tcfg["distroart"].getTable().keys:
        # Validate distroart objects
        if not tcfg["distroart"][distro].contains("margin"):
            echo &"ERROR: {path}:distroart:{distro} - missing 'margin'!"
            quit(1)
        if not tcfg["distroart"][distro].contains("art"):
            echo &"ERROR: {path}:distroart:{distro} - missing 'art'!"
            quit(1)
        
        # Generate Logo Objects
        var newLogo: Logo 
        var tmargin = tcfg["distroart"][distro]["margin"]
        newLogo.margin = [tmargin[0].getInt(), tmargin[1].getInt(), tmargin[2].getInt()]
        for line in tcfg["distroart"][distro]["art"].getElems:
            newLogo.art.add(line.getStr())

        # Inflate distroart table with alias if exists
        if tcfg["distroart"][distro].contains("alias"):
            let raw_alias_list = tcfg["distroart"][distro]["alias"].getStr().split(",")
            var alias_list: seq[string]
            for alias in raw_alias_list:
                alias_list.add(alias.strip())
            
            newLogo.isAlias = true

            for name in alias_list:
                if result.distroart.hasKey(name):
                    echo &"ERROR: {path}:distroart:{distro} - alias '{name}' already exists!"
                    quit(1)
                
                for c in name: # Check if name is a valid alias
                    if not (c in ALLOWED_NAME_CHARS):
                        echo &"ERROR: {path}:distroart:{distro} - '{name}' is not a valid alias!"
                        quit(1)

                result.distroart[name] = newLogo # Add alias to result

        newLogo.isAlias = false

        result.distroart[distro] = newLogo # Add distroart obj to result

    if not result.distroart.contains("default"): # Validate that default alias exists
        echo &"ERROR: {path}:distroart - missing 'default'!"
        quit(1)

    result.stats = tcfg["stats"]
    result.misc = tcfg["misc"]

proc getAllDistros*(cfg: Config): seq[string] =
    ## Function that returns all keys of distroart Table
    let distroart = cfg.distroart
    for k in distroart.keys:
        if not distroart[k].isAlias:
            result.add(k)