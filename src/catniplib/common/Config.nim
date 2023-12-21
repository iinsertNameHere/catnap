import "Toml"
from "Definitions" import Config, STATNAMES, STATKEYS

proc LoadConfig*(path: string): Config =
    ## Lads a config file and validates it
    let tcfg = Toml.parseFile(path)
    
    if not tcfg.contains("stats"):
        echo "ERROR: catnip.json - missing 'stats'!"
        quit(1)

    for statname in STATNAMES:
        if not tcfg["stats"].contains(statname):
            echo "ERROR: catnip.json->stats - missing '" & statname & "'!"
            quit(1)
        else:
            for statkey in STATKEYS:
                if not tcfg["stats"][statname].contains(statkey):
                    echo "ERROR: catnip.json->stats->" & statname & " - missing '" & statkey & "'!"
                    quit(1)  
    if not tcfg["stats"].contains("colors"):
        echo "ERROR: catnip.json->stats - missing 'colors'!"
        quit(1)
    else:
        for statkey in STATKEYS & @["symbol"]:
            if not tcfg["stats"]["colors"].contains(statkey):
                    echo "ERROR: catnip.json->stats->colors - missing '" & statkey & "'!"
                    quit(1)

    if not tcfg.contains("distroart"):
        echo "ERROR: catnip.json - missing 'distroart'!"
        quit(1)
    if not tcfg["distroart"].contains("default"):
        echo "ERROR: catnip.json->distroart - missing 'default'!"
        quit(1)
    
    result.stats = tcfg["stats"]
    result.distroart = tcfg["distroart"]