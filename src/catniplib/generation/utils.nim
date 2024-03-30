import unicode
import tables
import strutils

from "../global/definitions" import Stats, Stat, FetchInfo, STATNAMES
from "stats" import newStat
import "../terminal/colors"

proc repeat*(s: string, i: int): string =
    ## Repeats a string 's', 'i' times
    for _ in countup(0, i):
        result &= s

proc reallen*(s: string): int =
    ## Get the length of a string without ansi color codes
    result = Uncolorize(s).runeLen

proc buildStatBlock*(stat_names: seq[string], stats: Stats, fi: FetchInfo): seq[string] =
    ## Build output lines from Stats object and FetchInfo object

    var sb: seq[string]
    proc addStat(stat: Stat, value: string) =
        ## Function to add a stat/value pair to the result
        var line = stat.icon & " " & stat.name
        while uint(line.runeLen) < stats.maxlen:
            line &= " "
        sb.add("│ " & stat.color.Colorize() & line & colors.Default & " │ " & value)

    let colorval = Colorize( # Construct color showcase
        "(WE)"&stats.color_symbol&
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
    sb.add("╭" & "─".repeat(int(stats.maxlen + 1)) & "╮")

    for stat in stat_names:
        if stat == "colors": continue
        
        if stat.split('_')[0] == "sep":
            sb.add("├" & "─".repeat(int(stats.maxlen + 1)) & "┤")
            continue

        if stats.list[stat] != NIL_STAT:
            addStat(stats.list[stat], fi.list[stat])

    if stats.list["colors"] != NIL_STAT:
        addStat(stats.list["colors"], colorval)
    sb.add("╰" & "─".repeat(int(stats.maxlen + 1)) & "╯")

    return sb
