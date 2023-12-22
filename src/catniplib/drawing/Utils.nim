import unicode
from "../common/Definitions" import Stats, Stat, FetchInfo
import "Colors"

proc repeat*(s: string, i: int): string =
    for _ in countup(0, i):
        result &= s

proc reallen*(s: string): int =
    result = Colors.Uncolorize(s).runeLen

proc build*(stats: Stats, fi: FetchInfo): seq[string] =
    var sb: seq[string]
    proc addStat(stat: Stat, value: string) =
        var line = stat.icon & " " & stat.name
        while uint(line.runeLen) < stats.maxlen:
            line &= " "
        sb.add("│ " & stat.color.Colorize() & line & Colors.Default & " │ " & value)
    
    let colorval = Colors.Colorize(
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

    sb.add("╭" & "─".repeat(int(stats.maxlen + 1)) & "╮")
    addStat(stats.username, fi.username)
    addStat(stats.hostname, fi.hostname)
    addStat(stats.uptime,   fi.uptime)
    addStat(stats.distro,   fi.distro)
    addStat(stats.kernel,   fi.kernel)
    addStat(stats.desktop,  fi.desktop)
    addStat(stats.shell,    fi.shell)
    sb.add("├" & "─".repeat(int(stats.maxlen + 1)) & "┤")
    addStat(stats.colors, colorval)
    sb.add("╰" & "─".repeat(int(stats.maxlen + 1)) & "╯")

    return sb