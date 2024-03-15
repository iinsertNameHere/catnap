from "../common/defs" import Stats, Stat, Color
import "../common/toml"
import unicode

proc newStat*(icon: string, name: string, color: Color): Stat =
    ## Create a new Stat object
    result.icon = icon
    result.name = name
    result.color = color

proc newStats*(): Stats =
    ## Create a new Stats object
    result.maxlen = 0

#######################################
##        Set Value Functions        ##
#######################################

proc setUsername*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.username = newStat("", "", "")
        return
    
    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.username = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setHostname*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.hostname = newStat("", "", "")
        return
    
    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.hostname = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setUptime*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.uptime = newStat("", "", "")
        return

    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.uptime = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setDistro*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.distro = newStat("", "", "")
        return

    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.distro = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setKernel*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.kernel = newStat("", "", "")
        return
    
    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.kernel = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setDesktop*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.desktop = newStat("", "", "")
        return

    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.desktop = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setShell*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.shell = newStat("", "", "")
        return
    
    # Merge icon with stat name and color
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.shell = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setColors*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil: # Set username to empty stat
        stats.colors = newStat("", "", "")
        return
    
    # Merge icon with stat name, color and symbol
    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.colors = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())
    stats.color_symbol = rawstat["symbol"].getStr()