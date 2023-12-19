import json
from "Definitions" import Config, STATNAMES, STATKEYS

proc LoadConfig*(path: string): Config =
    ## Lads a config file and validates it
    let jcfg = parseJson(readFile("/home/iinsert/.config/catnip.json"))
    
    if jcfg{"stats"} == nil:
        echo "ERROR: catnip.json - missing 'stats'!"
        quit(1)

    for statname in STATNAMES:
        var stat = jcfg["stats"]{statname}
        if stat == nil:
            echo "ERROR: catnip.json->stats - missing '" & statname & "'!"
            quit(1)
        else:
            for statkey in STATKEYS:
                if stat{statkey} == nil:
                    echo "ERROR: catnip.json->stats->" & statname & " - missing '" & statkey & "'!"
                    quit(1)  
    if jcfg["stats"]{"colors"} == nil:
        echo "ERROR: catnip.json->stats - missing 'colors'!"
        quit(1)
    else:
        for statkey in STATKEYS & @["symbol"]:
            if jcfg["stats"]["colors"]{statkey} == nil:
                    echo "ERROR: catnip.json->stats->colors - missing '" & statkey & "'!"
                    quit(1)

    if jcfg{"distroart"} == nil:
        echo "ERROR: catnip.json - missing 'distroart'!"
        quit(1)
    if jcfg["distroart"]{"default"} == nil:
        echo "ERROR: catnip.json->distroart - missing 'default'!"
        quit(1)
    
    result.stats = jcfg["stats"]
    result.distroart = jcfg["distroart"]