from "../common/definitions" import Stats, Stat, Color
import "../common/parsetoml"
import unicode

proc newStat*(icon: string, name: string, color: Color): Stat =
    ## Create a new Stat object
    result.icon = icon
    result.name = name
    result.color = color

proc newStats*(): Stats =
    ## Create a new Stats object
    result.maxlen = 0

template setStat*(stats: var Stats, stat_name: untyped, rawstat: TomlValueRef): untyped =
    ## Template function that generates a Stat object an parses it to the related stats field
    if rawstat == nil: # Set to empty stat
        stats.`stat_name` = newStat("", "", "")
        return

    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.`stat_name` = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())
    if astToStr(stat_name) == "colors": stats.color_symbol = rawstat["symbol"].getStr()
