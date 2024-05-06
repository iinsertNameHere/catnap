from "../global/definitions" import Stats, Stat, Color, STATNAMES

import parsetoml
import unicode
import tables

proc newStat*(icon: string, name: string, color: Color): Stat =
    # Create a new Stat object
    result.icon = icon
    result.name = name
    result.color = color

proc newStats*(): Stats =
    # Create a new Stanamets object
    result.maxlen = 0
    for name in STATNAMES:
        result.list[name] = newStat("", "", "")

proc setStat*(stats: var Stats, stat_name: string, rawstat: TomlValueRef) =
    # Function that generates a Stat object an parses it to the related stats field
    if rawstat != nil: # Set to empty stat
        # Merge icon with stat name and color
        let l = uint(unicode.runeLen(rawstat["icon"].getStr()) + unicode.runeLen(rawstat["name"].getStr()) + 1)
        if l > stats.maxlen:
            stats.maxlen = l
        stats.list[stat_name] = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())
        if stat_name == "colors": stats.color_symbol = rawstat["symbol"].getStr()
