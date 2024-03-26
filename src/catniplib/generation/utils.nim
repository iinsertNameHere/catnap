import unicode
import tables

from "../global/definitions" import Stats, Stat, FetchInfo
from "stats" import newStat
import "../terminal/colors"

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
    if stats.list["username"] != NIL_STAT:
        addStat(stats.list["username"], fi.username)

    if stats.list["hostname"] != NIL_STAT:
        addStat(stats.list["hostname"], fi.hostname)

    if stats.list["uptime"] != NIL_STAT:
        addStat(stats.list["uptime"], fi.uptime)

    if stats.list["distro"] != NIL_STAT:
        addStat(stats.list["distro"], fi.distro)

    if stats.list["kernel"] != NIL_STAT:
        addStat(stats.list["kernel"], fi.kernel)

    if stats.list["desktop"] != NIL_STAT:
        addStat(stats.list["desktop"], fi.desktop)

    if stats.list["terminal"] != NIL_STAT:
        addStat(stats.list["terminal"], fi.terminal)

    if stats.list["shell"] != NIL_STAT:
        addStat(stats.list["shell"], fi.shell)

    if stats.list["cpu"] != NIL_STAT:
        addStat(stats.list["cpu"], fi.cpu)

    if stats.list["memory"] != NIL_STAT:
        addStat(stats.list["memory"], fi.memory)

    if stats.list["disk"] != NIL_STAT:
        addStat(stats.list["disk"], fi.disk)

    if stats.list["colors"] != NIL_STAT:
        sb.add("├" & "─".repeat(int(stats.maxlen + 1)) & "┤")
        addStat(stats.list["colors"], colorval)
    sb.add("╰" & "─".repeat(int(stats.maxlen + 1)) & "╯")

    return sb
