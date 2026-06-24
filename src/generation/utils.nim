import unicode
import strformat
import tables

from "../config/types" import Config, StatEntry
from "../system/types" import FetchInfo
import "../common/colors"
import "../common/logging"

proc fill*(s: string, i: int): string =
    for _ in countup(0, i):
        result &= s

proc reallen*(s: string): int =
    result = Uncolorize(s).runeLen

proc buildStatBlock*(statEntries: seq[StatEntry], config: Config, fi: FetchInfo, margin_top: int): seq[string] =
    var sb: seq[string]

    for _ in countup(1, margin_top):
        sb.add("")

    let borderstyle = config.misc.borderstyle

    var maxlen: uint = 0
    for entry in statEntries:
        if entry.id == "separator" or entry.id == "colors": continue
        let l = uint(unicode.runeLen(entry.icon & " " & entry.name) + 1)
        if l > maxlen: maxlen = l

    let text_color = config.misc.text_color

    proc addStat(entry: StatEntry, value: string) =
        var line = entry.icon & " " & entry.name
        while uint(line.runeLen) < maxlen:
            line &= " "
        case borderstyle:
            of "line":       sb.add("│ " & entry.color & line & colors.Default & " │ " & text_color & value & colors.Default)
            of "dashed":     sb.add("┊ " & entry.color & line & colors.Default & " ┊ " & text_color & value & colors.Default)
            of "dotted":     sb.add("┇ " & entry.color & line & colors.Default & " ┇ " & text_color & value & colors.Default)
            of "noborder":   sb.add("  " & entry.color & line & colors.Default & "   " & text_color & value & colors.Default)
            of "doubleline": sb.add("║ " & entry.color & line & colors.Default & " ║ " & text_color & value & colors.Default)
            else:
                logError(&"{config.configFile}:borderstyle - Invalid style")
                quit(1)

    var fetchinfolist_keys: seq[string]
    for k in fi.list.keys:
        fetchinfolist_keys.add(k)

    case borderstyle:
        of "line":       sb.add("╭" & "─".fill(int(maxlen + 1)) & "╮")
        of "dashed":     sb.add("╭" & "┄".fill(int(maxlen + 1)) & "╮")
        of "dotted":     sb.add("•" & "•".fill(int(maxlen + 1)) & "•")
        of "noborder":   sb.add(" " & " ".fill(int(maxlen + 1)) & " ")
        of "doubleline": sb.add("╔" & "═".fill(int(maxlen + 1)) & "╗")
        else:
            logError(&"{config.configFile}:borderstyle - Invalid style")
            quit(1)

    for entry in statEntries:
        if entry.id == "colors": continue

        if entry.id == "separator":
            case borderstyle:
                of "line":       sb.add("├" & entry.color & "─".fill(int(maxlen + 1)) & colors.Default & "┤")
                of "dashed":     sb.add("┊" & entry.color & "┄".fill(int(maxlen + 1)) & colors.Default & "┊")
                of "dotted":     sb.add("┇" & entry.color & "•".fill(int(maxlen + 1)) & colors.Default & "┇")
                of "noborder":   sb.add(" " & " ".fill(int(maxlen + 1)) & " ")
                of "doubleline": sb.add("╠" & entry.color & "═".fill(int(maxlen + 1)) & colors.Default & "╣")
            continue

        if entry.id notin fetchinfolist_keys:
            logError(&"Unknown StatName '{entry.id}'!")

        addStat(entry, fi.list[entry.id]())

    for entry in statEntries:
        if entry.id == "colors":
            let sym = entry.symbol
            let colorval =
                "\e[37m" & sym & " \e[31m" & sym & " \e[33m" & sym & " \e[32m" & sym &
                " \e[36m" & sym & " \e[34m" & sym & " \e[35m" & sym & " \e[30m" & sym & " \e[0m"
            addStat(entry, colorval)
            break

    case borderstyle:
        of "line":       sb.add("╰" & "─".fill(int(maxlen + 1)) & "╯")
        of "dashed":     sb.add("╰" & "┄".fill(int(maxlen + 1)) & "╯")
        of "dotted":     sb.add("•" & "•".fill(int(maxlen + 1)) & "•")
        of "noborder":   sb.add(" " & " ".fill(int(maxlen + 1)) & " ")
        of "doubleline": sb.add("╚" & "═".fill(int(maxlen + 1)) & "╝")
        else: discard

    return sb
