import unicode
import tables
import strutils
import strformat
import parsetoml

from "../global/definitions" import Stats, Stat, Config, FetchInfo, STATNAMES
from "stats" import newStat
import "../terminal/colors"
import "../terminal/logging"

proc repeat*(s: string, i: int): string =
    # Repeats a string 's', 'i' times
    for _ in countup(0, i):
        result &= s

proc reallen*(s: string): int =
    # Get the length of a string without ansi color codes
    result = Uncolorize(s).runeLen

proc buildStatBlock*(stat_names: seq[string], stats: Stats, config: Config, fi: FetchInfo, margin_top: int): seq[string] =
    # Build output lines from Stats object and FetchInfo object

    var sb: seq[string]

    for idx in countup(1, margin_top):
        sb.add("")

    var borderstyle = ""
    if config.misc.contains("borderstyle"):
        borderstyle = config.misc["borderstyle"].getStr()

    proc addStat(stat: Stat, value: string) =
        # Function to add a stat/value pair to the result
        var line = stat.icon & " " & stat.name
        while uint(line.runeLen) < stats.maxlen:
            line &= " "
        case borderstyle:
            of "line":
                sb.add("│ " & stat.color.Colorize() & line & colors.Default & " │ " & value)
            of "dashed":
                sb.add("┊ " & stat.color.Colorize() & line & colors.Default & " ┊ " & value)
            of "dotted":
                sb.add("┇ " & stat.color.Colorize() & line & colors.Default & " ┇ " & value)
            of "noborder":
                sb.add("  " & stat.color.Colorize() & line & colors.Default & "   " & value)
            of "doubleline":
                sb.add("║ " & stat.color.Colorize() & line & colors.Default & " ║ " & value)
            else: # Invalid borderstyle
                logError(&"{config.configFile}:misc:borderstyle - Invalid style")
                quit(1)

    let colorval = Colorize( # Construct color showcase
        " (WE)"&stats.color_symbol&
        " (RD)"&stats.color_symbol&
        " (YW)"&stats.color_symbol&
        " (GN)"&stats.color_symbol&
        " (CN)"&stats.color_symbol&
        " (BE)"&stats.color_symbol&
        " (MA)"&stats.color_symbol&
        " (BK)"&stats.color_symbol&
        "!DT!"
    )

    let NIL_STAT = newStat("", "", "") # Define empty Stat object

    # Construct the stats section with all stats that are not NIL
    case borderstyle:
        of "line":
            sb.add("╭" & "─".repeat(int(stats.maxlen + 1)) & "╮")
        of "dashed":
            sb.add("╭" & "┄".repeat(int(stats.maxlen + 1)) & "╮")
        of "dotted":
            sb.add("•" & "•".repeat(int(stats.maxlen + 1)) & "•")
        of "noborder":
            sb.add(" " & " ".repeat(int(stats.maxlen + 1)) & " ")
        of "doubleline":
            sb.add("╔" & "═".repeat(int(stats.maxlen + 1)) & "╗")
    var fetchinfolist_keys: seq[string] 
    for k in fi.list.keys:
        fetchinfolist_keys.add(k)

    for stat in stat_names:
        if stat == "colors": continue
        
        if stat.split('_')[0] == "sep":
            case borderstyle:
                of "line":
                    sb.add("├" & "─".repeat(int(stats.maxlen + 1)) & "┤")
                of "dashed":
                    sb.add("┊" & "┄".repeat(int(stats.maxlen + 1)) & "┊")
                of "dotted":
                    sb.add("┇" & "•".repeat(int(stats.maxlen + 1)) & "┇")
                of "noborder":
                    sb.add(" " & " ".repeat(int(stats.maxlen + 1)) & " ")
                of "doubleline":
                    sb.add("╠" & "═".repeat(int(stats.maxlen + 1)) & "╣")
            continue

        if stat notin fetchinfolist_keys:
            logError(&"Unknown StatName '{stat}'!")

        if stats.list[stat] != NIL_STAT:
            addStat(stats.list[stat], fi.list[stat]())
    
    # Color stat
    if stats.list["colors"] != NIL_STAT:
        addStat(stats.list["colors"], colorval)
    case borderstyle:
        of "line":
            sb.add("╰" & "─".repeat(int(stats.maxlen + 1)) & "╯")
        of "dashed":
            sb.add("╰" & "┄".repeat(int(stats.maxlen + 1)) & "╯")
        of "dotted":
            sb.add("•" & "•".repeat(int(stats.maxlen + 1)) & "•")
        of "noborder":
            sb.add(" " & " ".repeat(int(stats.maxlen + 1)) & " ")
        of "doubleline":
            sb.add("╚" & "═".repeat(int(stats.maxlen + 1)) & "╝")
    return sb
