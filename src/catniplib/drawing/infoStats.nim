from "../common/defs" import Stats, Stat, Color
import "../common/toml"
import unicode

proc newStat*(icon: string, name: string, color: Color): Stat =
    result.icon = icon
    result.name = name
    result.color = color

proc newStats*(): Stats =
    result.maxlen = 0

proc setUsername*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.username = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.username = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setHostname*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.hostname = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.hostname = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setUptime*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.uptime = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.uptime = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setDistro*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.distro = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.distro = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setKernel*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.kernel = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.kernel = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setDesktop*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.desktop = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.desktop = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setShell*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.shell = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.shell = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())

proc setColors*(stats: var Stats, rawstat: TomlValueRef) =
    if rawstat == nil:
        stats.colors = newStat("", "", "")
        return

    let l = uint(rawstat["icon"].getStr().runeLen + rawstat["name"].getStr().runeLen + 1)
    if l > stats.maxlen:
        stats.maxlen = l
    stats.colors = newStat(rawstat["icon"].getStr(), rawstat["name"].getStr(), rawstat["color"].getStr())
    stats.color_symbol = rawstat["symbol"].getStr()