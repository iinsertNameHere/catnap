import unicode
import strformat
import strutils
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

proc parsePercent*(s: string): float =
    let idx = s.find('%')
    if idx < 0: return -1.0
    var i = idx - 1
    while i >= 0 and s[i].isDigit(): dec i
    let numStr = s[i + 1 ..< idx]
    if numStr.len == 0: return -1.0
    try: result = parseFloat(numStr) / 100.0
    except ValueError: result = -1.0

proc renderGraph*(pct: float, width: int, style: string, tc: string, fg: string, bg: string): string =
    let p = min(1.0, max(0.0, pct))

    case style:
    of "blocks":
        let f = int(p * float(width))
        fg & "█".repeat(f) & bg & "░".repeat(width - f) & tc
    of "ascii":
        let inner = width - 2
        let f = int(p * float(inner))
        tc & "[" & fg & "#".repeat(f) & bg & "-".repeat(inner - f) & tc & "]"
    of "dots":
        let f = int(p * float(width))
        fg & "●".repeat(f) & bg & "○".repeat(width - f) & tc
    of "thin":
        let f = int(p * float(width))
        fg & "▰".repeat(f) & bg & "▱".repeat(width - f) & tc
    of "pacman":
        let inner = width - 2
        let f = int(p * float(inner))

        var bar = ""
        if f >= inner:
            bar = bg & "-".repeat(inner)
        elif f > 0:
            bar = bg & "-".repeat(f - 1) & fg & (if (f + 1) %% 3 == 0: "c" else: "C")
            for i in countup(f + 1, inner):
                if (i + 1) %% 3 == 0:
                  bar = bar & bg & "o"
                else:
                  bar = bar & " "
        else:
            for i in countup(f + 1, inner):
                if (i + 1) %% 3 == 0:
                  bar = bar & bg & "o"
                else:
                  bar = bar & " "

        tc & "[" & bar & tc & "]"
    of "precise":
        let inner = width - 2
        let eighths = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]
        let steps = inner * 8
        let filled = int(p * float(steps))
        let fullChars = filled div 8
        let remainder = filled mod 8
        tc & "|" &
        fg & "█".repeat(fullChars) &
        (if remainder > 0: eighths[remainder] else: "") &
        " ".repeat(inner - fullChars - min(1, remainder)) &
        tc & "|"

    else:
        logError("Unknown graph style: " & style)
        " "

proc buildStatBlock*(statEntries: seq[StatEntry], config: Config, fi: FetchInfo, margin_top: int): seq[string] =
    var sb: seq[string]

    for _ in countup(1, margin_top):
        sb.add("")

    let border_style = config.misc.border_style

    var maxlen: uint = 0
    for entry in statEntries:
        if entry.id == "separator" or entry.id == "colors": continue
        let l = uint(unicode.runeLen(entry.icon & " " & entry.name) + 1)
        if l > maxlen: maxlen = l

    let text_color = config.misc.text_color
    let bc = config.misc.border_color

    proc addStat(entry: StatEntry, value: string) =
        var line = entry.icon & " " & entry.name
        while uint(line.runeLen) < maxlen:
            line &= " "
        case border_style:
            of "single":       sb.add(bc & "│ " & entry.color & line & colors.Default & bc & " │ " & text_color & value & colors.Default)
            of "dashed":     sb.add(bc & "┊ " & entry.color & line & colors.Default & bc & " ┊ " & text_color & value & colors.Default)
            of "dotted":     sb.add(bc & "┇ " & entry.color & line & colors.Default & bc & " ┇ " & text_color & value & colors.Default)
            of "none":   sb.add(bc & "  " & entry.color & line & colors.Default & bc & "   " & text_color & value & colors.Default)
            of "double": sb.add(bc & "║ " & entry.color & line & colors.Default & bc & " ║ " & text_color & value & colors.Default)
            else:
                logError(&"{config.configFile}:border_style - Invalid style")
                quit(1)

    var fetchinfolist_keys: seq[string]
    for k in fi.list.keys:
        fetchinfolist_keys.add(k)

    case border_style:
        of "single":       sb.add(bc & "╭" & "─".fill(int(maxlen + 1)) & "╮" & colors.Default)
        of "dashed":     sb.add(bc & "╭" & "┄".fill(int(maxlen + 1)) & "╮" & colors.Default)
        of "dotted":     sb.add(bc & "•" & "•".fill(int(maxlen + 1)) & "•" & colors.Default)
        of "none":   sb.add(bc & " " & " ".fill(int(maxlen + 1)) & " " & colors.Default)
        of "double": sb.add(bc & "╔" & "═".fill(int(maxlen + 1)) & "╗" & colors.Default)
        else:
            logError(&"{config.configFile}:border_style - Invalid style")
            quit(1)

    for entry in statEntries:
        if entry.id == "colors": continue

        if entry.id == "separator":
            case border_style:
                of "single":       sb.add(bc & "├" & bc & "─".fill(int(maxlen + 1)) & bc & "┤" & colors.Default)
                of "dashed":     sb.add(bc & "┊" & bc & "┄".fill(int(maxlen + 1)) & bc & "┊" & colors.Default)
                of "dotted":     sb.add(bc & "┇" & bc & "•".fill(int(maxlen + 1)) & bc & "┇" & colors.Default)
                of "none":   sb.add(" " & " ".fill(int(maxlen + 1)) & " ")
                of "double": sb.add(bc & "╠" & bc & "═".fill(int(maxlen + 1)) & bc & "╣" & colors.Default)
            continue

        if entry.id notin fetchinfolist_keys:
            logError(&"Unknown StatName '{entry.id}'!")

        let rawValue = fi.list[entry.id]()
        if entry.graph:
            let pct = parsePercent(rawValue)
            let w = if entry.graphWidth > 0: entry.graphWidth else: config.misc.graph_width
            let s = entry.graphStyle
            let f = entry.graphFg
            let b = entry.graphBg
            addStat(entry, if pct >= 0.0: renderGraph(pct, w, s, text_color, f, b) & " " & rawValue else: rawValue)
        else:
            addStat(entry, rawValue)

    for entry in statEntries:
        if entry.id == "colors":
            let sym = entry.symbol
            let colorval =
                "\e[37m" & sym & " \e[31m" & sym & " \e[33m" & sym & " \e[32m" & sym &
                " \e[36m" & sym & " \e[34m" & sym & " \e[35m" & sym & " \e[30m" & sym & " \e[0m"
            addStat(entry, colorval)
            break

    case border_style:
        of "single":       sb.add(bc & "╰" & "─".fill(int(maxlen + 1)) & "╯" & colors.Default)
        of "dashed":     sb.add(bc & "╰" & "┄".fill(int(maxlen + 1)) & "╯" & colors.Default)
        of "dotted":     sb.add(bc & "•" & "•".fill(int(maxlen + 1)) & "•" & colors.Default)
        of "none":   sb.add(bc & " " & " ".fill(int(maxlen + 1)) & " " & colors.Default)
        of "double": sb.add(bc & "╚" & "═".fill(int(maxlen + 1)) & "╝" & colors.Default)
        else: discard

    return sb
