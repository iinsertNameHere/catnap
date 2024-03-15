import unicode

from "../common/defs" import Stats, Stat, FetchInfo
from "stats" import newStat
import "colors"

proc repeat*(s: string, i: int): string =
    ## Repeats a string 's', 'i' times
    for _ in countup(0, i):
        result &= s

proc reallen*(s: string): int =
    ## Get the length of a string without ansi color codes
    result = Uncolorize(s).runeLen

proc buildStatBlock*(stats: Stats, fi: FetchInfo): seq[string] =
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
    if stats.username != NIL_STAT:
        addStat(stats.username, fi.username)
    if stats.hostname != NIL_STAT:
        addStat(stats.hostname, fi.hostname)
    if stats.uptime != NIL_STAT:
        addStat(stats.uptime,   fi.uptime)
    if stats.distro != NIL_STAT:
        addStat(stats.distro,   fi.distro)
    if stats.kernel != NIL_STAT:
        addStat(stats.kernel,   fi.kernel)
    if stats.desktop != NIL_STAT:
        addStat(stats.desktop,  fi.desktop)
    if stats.shell != NIL_STAT:
        addStat(stats.shell,    fi.shell)
    if stats.colors != NIL_STAT:
        sb.add("├" & "─".repeat(int(stats.maxlen + 1)) & "┤")
        addStat(stats.colors, colorval)
    sb.add("╰" & "─".repeat(int(stats.maxlen + 1)) & "╯")

    return sb