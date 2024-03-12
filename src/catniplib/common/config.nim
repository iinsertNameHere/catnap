import "toml"
from "defs" import Config, STATNAMES, STATKEYS
from os import fileExists
import strformat

proc LoadConfig*(path: string): Config =
    ## Lads a config file and validates it
    
    if not fileExists(path):
        echo &"ERROR: {path} - file not found!"
        quit(1)

    let tcfg = toml.parseFile(path)
    
    if not tcfg.contains("stats"):
        echo &"ERROR: {path} - missing 'stats'!"
        quit(1)

    for statname in STATNAMES:
        if not tcfg["stats"].contains(statname):
            echo &"ERROR: {path}->stats - missing '" & statname & "'!"
            quit(1)
        else:
            for statkey in STATKEYS:
                if not tcfg["stats"][statname].contains(statkey):
                    echo &"ERROR: {path}:stats:" & statname & " - missing '" & statkey & "'!"
                    quit(1)  
    if not tcfg["stats"].contains("colors"):
        echo &"ERROR: {path}->stats - missing 'colors'!"
        quit(1)
    else:
        for statkey in STATKEYS & @["symbol"]:
            if not tcfg["stats"]["colors"].contains(statkey):
                    echo &"ERROR: {path}:stats:colors - missing '" & statkey & "'!"
                    quit(1)

    if not tcfg.contains("distroart"):
        echo &"ERROR: {path} - missing 'distroart'!"
        quit(1)
    if not tcfg["distroart"].contains("default"):
        echo &"ERROR: {path}:distroart - missing 'default'!"
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

    if not tcfg["misc"]["figletLogos"].contains("margin"):
        echo &"ERROR: {path}:misc:figletLogos - missing 'margin'!"
        quit(1)
    
    result.stats = tcfg["stats"]
    result.distroart = tcfg["distroart"]
    result.misc = tcfg["misc"]