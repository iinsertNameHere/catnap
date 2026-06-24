import tables
import strutils
import os
import parser
import lexer

#### Types ####

type ConfigValueKind* = enum
    cvString
    cvChar
    cvNumber
    cvBool
    cvHex       # #cba6f7 => decoded to ANSI at resolve time
    cvAnsi      # !31     => decoded to ANSI at resolve time
    cvRgb       # (r g b) => decoded to ANSI at resolve time
    cvList
    cvStat
    cvArt       # {%name [...] margin=[...]}
    cvVarRef    # unresolved $name

type ConfigValue* = ref object
    case kind*: ConfigValueKind
    of cvString:  strVal*:  string
    of cvChar:    charVal*: string
    of cvNumber:  numVal*:  int
    of cvBool:    boolVal*: bool
    of cvHex:     hexVal*:  string
    of cvAnsi:    ansiVal*: string
    of cvRgb:     r*, g*, b*: int
    of cvList:    items*:   seq[ConfigValue]
    of cvStat:
        statId*:   string
        statArgs*: Table[string, ConfigValue]
    of cvArt:
        artNames*: seq[string]
        art*:      seq[string]    # raw strings, may contain {$var}
        margin*:   array[3, int]
    of cvVarRef:  refName*: string

type DslOutput* = object
    vars*: Table[string, ConfigValue]

type AnalyzeError* = object of CatchableError
type ResolveError* = object of CatchableError

#### Helpers ####

proc analyzeError(line: int, msg: string) =
    raise newException(AnalyzeError, "line " & $line & ": " & msg)

proc resolveError(msg: string) =
    raise newException(ResolveError, msg)

proc fmtCycle(chain: seq[string]): string =
    chain.join(" -> ") & " -> " & chain[0]

#### Color decoding ####

proc rgbToAnsi*(r, g, b: int): string =
    "\e[38;2;" & $r & ";" & $g & ";" & $b & "m"

proc hexToAnsi*(hex: string): string =
    let h = hex[1..^1]  # strip #
    case h.len:
        of 3:
            let r = parseHexInt(h[0..0] & h[0..0])
            let g = parseHexInt(h[1..1] & h[1..1])
            let b = parseHexInt(h[2..2] & h[2..2])
            rgbToAnsi(r, g, b)
        of 6:
            let r = parseHexInt(h[0..1])
            let g = parseHexInt(h[2..3])
            let b = parseHexInt(h[4..5])
            rgbToAnsi(r, g, b)
        else:
            resolveError("invalid hex color (expected 3 or 6 digits): " & hex)
            ""

proc ansiCodeToEscape*(code: string): string =
    # !31 -> \e[31m
    "\e[" & code[1..^1] & "m"

proc valueToString*(v: ConfigValue): string =
    case v.kind:
    of cvString:  v.strVal
    of cvChar:    v.charVal
    of cvNumber:  $v.numVal
    of cvBool:    $v.boolVal
    of cvAnsi:    ansiCodeToEscape(v.ansiVal)
    of cvHex:     hexToAnsi(v.hexVal)
    of cvRgb:     rgbToAnsi(v.r, v.g, v.b)
    else:
        resolveError("cannot convert " & $v.kind & " to string")
        ""

#### Import pre-pass ####

proc runImportPass*(nodes: seq[Node], baseDir: string,
                    visiting: var seq[string]): seq[Node] =
    for n in nodes:
        if n == nil: continue
        if n.kind == nkImport:
            let rawPath = baseDir / n.path
            if not fileExists(rawPath):
                analyzeError(n.line, "imported file not found: " & rawPath)
            let path = expandFilename(rawPath)

            if path in visiting:
                let cycle = visiting[visiting.find(path)..^1] & @[path]
                raise newException(AnalyzeError,
                    "line " & $n.line & ": circular import detected: " &
                    cycle.join(" -> "))

            visiting.add path
            let src    = readFile(path)
            let toks   = tokenize(src)
            let parsed = parse(toks)
            let importBaseDir = parentDir(path)
            result.add runImportPass(parsed, importBaseDir, visiting)
            discard visiting.pop()
        else:
            result.add n

proc runImportPass*(nodes: seq[Node], baseDir: string): seq[Node] =
    var visiting: seq[string] = @[]
    runImportPass(nodes, baseDir, visiting)

#### Default color injection ####

proc injectDefaultColors*(vars: var Table[string, ConfigValue]) =
    const defaults = [
        ("black",         "!30"), ("red",           "!31"),
        ("green",         "!32"), ("yellow",         "!33"),
        ("blue",          "!34"), ("magenta",        "!35"),
        ("cyan",          "!36"), ("white",          "!37"),
        ("bright_black",  "!90"), ("bright_red",     "!91"),
        ("bright_green",  "!92"), ("bright_yellow",  "!93"),
        ("bright_blue",   "!94"), ("bright_magenta", "!95"),
        ("bright_cyan",   "!96"), ("bright_white",   "!97"),
        ("reset",         "!0"),
    ]
    for (name, code) in defaults:
        if not vars.hasKey(name):
            vars[name] = ConfigValue(kind: cvAnsi, ansiVal: code)

#### Analyze pass ####

proc analyzeValue(n: Node, inStatArg: bool = false): ConfigValue

proc analyzeScalar(n: Node): ConfigValue =
    case n.kind:
        of nkString:  ConfigValue(kind: cvString,  strVal:  n.strVal)
        of nkChar:    ConfigValue(kind: cvChar,    charVal: n.charVal)
        of nkNumber:  ConfigValue(kind: cvNumber,  numVal:  parseInt(n.numVal))
        of nkBool:    ConfigValue(kind: cvBool,    boolVal: n.boolVal)
        of nkHex:     ConfigValue(kind: cvHex,     hexVal:  n.hexVal)
        of nkAnsi:    ConfigValue(kind: cvAnsi,    ansiVal: n.ansiVal)
        of nkRgb:     ConfigValue(kind: cvRgb,     r: n.r, g: n.g, b: n.b)
        of nkVarRef:  ConfigValue(kind: cvVarRef,  refName: n.refName[1..^1]) # strip $
        else:
            analyzeError(n.line, "expected scalar value, got " & $n.kind)
            nil

proc analyzeArtMargin(n: Node): array[3, int] =
    if n == nil:
        return [0, 1, 1]
    if n.kind != nkList:
        analyzeError(n.line, "margin must be a list of numbers")
    let items = n.items
    for item in items:
        if item.kind != nkNumber:
            analyzeError(item.line, "margin values must be numbers")
    case items.len:
        of 1:
            let v = parseInt(items[0].numVal)
            [v, v, v]
        of 2:
            let top   = parseInt(items[0].numVal)
            let sides = parseInt(items[1].numVal)
            [top, sides, sides]
        of 3:
            [parseInt(items[0].numVal), parseInt(items[1].numVal), parseInt(items[2].numVal)]
        else:
            analyzeError(n.line, "margin must have 1, 2, or 3 values")
            [0, 0, 0]

proc analyzeValue(n: Node, inStatArg: bool = false): ConfigValue =
    case n.kind:
        of nkString, nkChar, nkNumber, nkBool, nkHex, nkAnsi, nkRgb, nkVarRef:
            analyzeScalar(n)

        of nkList:
            if inStatArg:
                var items: seq[ConfigValue] = @[]
                for item in n.items:
                    case item.kind:
                        of nkString, nkChar, nkNumber, nkBool, nkHex, nkAnsi, nkRgb, nkVarRef:
                            items.add analyzeScalar(item)
                        of nkList:
                            analyzeError(item.line, "nested lists are not allowed in stat named args")
                        of nkStatRef:
                            analyzeError(item.line, "stat refs are not allowed in stat named args")
                        else:
                            analyzeError(item.line, "unexpected node in stat arg list: " & $item.kind)
                ConfigValue(kind: cvList, items: items)
            else:
                var items: seq[ConfigValue] = @[]
                for item in n.items:
                    items.add analyzeValue(item, inStatArg = false)
                ConfigValue(kind: cvList, items: items)

        of nkStatRef:
            if inStatArg:
                analyzeError(n.line, "stat refs are not allowed as stat named arg values")
            var args = initTable[string, ConfigValue]()
            for argNode in n.namedArgs:
                let v = analyzeValue(argNode.argValue, inStatArg = true)
                args[argNode.argKey] = v
            ConfigValue(kind: cvStat, statId: n.statId[1..^1], statArgs: args) # strip @

        of nkArtBlock:
            var artStrings: seq[string] = @[]
            for lineNode in n.artLines:
                if lineNode.kind != nkString:
                    analyzeError(lineNode.line, "art lines must be string literals")
                artStrings.add lineNode.strVal
            let margin = analyzeArtMargin(n.artMarginNode)
            ConfigValue(kind: cvArt, artNames: n.artNames,
                        art: artStrings, margin: margin)

        else:
            analyzeError(n.line, "unexpected node kind in value position: " & $n.kind)
            nil

proc analyzeNodes*(nodes: seq[Node]): DslOutput =
    result.vars = initTable[string, ConfigValue]()
    injectDefaultColors(result.vars)
    for n in nodes:
        if n == nil: continue
        case n.kind:
            of nkVarAssign:
                let name = n.varName[1..^1]  # strip $
                result.vars[name] = analyzeValue(n.value)
            of nkImport:
                analyzeError(n.line, "unexpected import node during analyze (import pre-pass skipped?)")
            else:
                analyzeError(n.line, "unexpected top-level node: " & $n.kind)

#### String interpolation ####

proc interpolateString(s: string, env: Table[string, ConfigValue],
                       visiting: var seq[string]): string

proc resolveValue(v: ConfigValue, env: Table[string, ConfigValue],
                  visiting: var seq[string]): ConfigValue

proc interpolateString(s: string, env: Table[string, ConfigValue],
                       visiting: var seq[string]): string =
    var i = 0
    while i < s.len:
        if i + 1 < s.len and s[i] == '{' and s[i+1] == '$':
            let start = i + 2
            var j = start
            while j < s.len and s[j] != '}':
                inc j
            if j < s.len:
                let varName = s[start..<j]
                if not env.hasKey(varName):
                    resolveError("undefined variable in interpolation: $" & varName)
                if varName in visiting:
                    let cycle = visiting[visiting.find(varName)..^1]
                    resolveError("circular variable reference: " & fmtCycle(cycle))
                visiting.add varName
                let resolved = resolveValue(env[varName], env, visiting)
                discard visiting.pop()
                result &= valueToString(resolved)
                i = j + 1
            else:
                result &= s[i]
                inc i
        else:
            result &= s[i]
            inc i

#### Resolution pass ####

proc resolveValue(v: ConfigValue, env: Table[string, ConfigValue],
                  visiting: var seq[string]): ConfigValue =
    case v.kind:
        of cvVarRef:
            let name = v.refName
            if not env.hasKey(name):
                resolveError("undefined variable: $" & name)

            if name in visiting:
                let cycle = visiting[visiting.find(name)..^1]
                resolveError("circular variable reference: " & fmtCycle(cycle))

            visiting.add name
            result = resolveValue(env[name], env, visiting)
            discard visiting.pop()

        of cvString:
            if '{' in v.strVal:
                result = ConfigValue(kind: cvString,
                    strVal: interpolateString(v.strVal, env, visiting))
            else:
                result = v

        of cvList:
            var items: seq[ConfigValue] = @[]
            for item in v.items:
                items.add resolveValue(item, env, visiting)
            result = ConfigValue(kind: cvList, items: items)

        of cvStat:
            var args = initTable[string, ConfigValue]()
            for key, val in v.statArgs:
                args[key] = resolveValue(val, env, visiting)
            result = ConfigValue(kind: cvStat, statId: v.statId, statArgs: args)

        of cvArt:
            var resolvedArt: seq[string] = @[]
            for line in v.art:
                if '{' in line:
                    resolvedArt.add interpolateString(line, env, visiting)
                else:
                    resolvedArt.add line
            result = ConfigValue(kind: cvArt, artNames: v.artNames,
                                 art: resolvedArt, margin: v.margin)

        else:
            result = v  # scalars are already fully resolved

proc resolveDslOutput*(cfg: DslOutput): DslOutput =
    result.vars = initTable[string, ConfigValue]()
    for name, val in cfg.vars:
        var visiting: seq[string] = @[name]
        result.vars[name] = resolveValue(val, cfg.vars, visiting)

#### Post-resolve validation ####

proc validateDslOutput*(output: DslOutput) =
    for name in ["stats", "distros", "layout"]:
        if not output.vars.hasKey(name):
            resolveError("required variable '$" & name & "' is not defined")

    let layoutVal = output.vars["layout"]
    if layoutVal.kind != cvString:
        resolveError("$layout must be a string value")
    const validLayouts = ["Inline", "ArtOnTop", "StatsOnTop"]
    if layoutVal.strVal notin validLayouts:
        resolveError("$layout must be one of: Inline, ArtOnTop, StatsOnTop (got: \"" & layoutVal.strVal & "\")")

    if output.vars.hasKey("borderstyle"):
        let bsVal = output.vars["borderstyle"]
        if bsVal.kind != cvString:
            resolveError("$borderstyle must be a string value")
        const validStyles = ["line", "dashed", "dotted", "noborder", "doubleline"]
        if bsVal.strVal notin validStyles:
            resolveError("$borderstyle must be one of: line, dashed, dotted, noborder, doubleline (got: \"" & bsVal.strVal & "\")")

    if output.vars.hasKey("stats_margin_top"):
        let smtVal = output.vars["stats_margin_top"]
        if smtVal.kind != cvNumber:
            resolveError("$stats_margin_top must be a number")

    let statsVal = output.vars["stats"]
    if statsVal.kind != cvList:
        resolveError("$stats must be a list")
    for i, item in statsVal.items:
        if item.kind != cvStat:
            resolveError("$stats[" & $i & "] must be a stat entry ({@statid ...})")
        let required = if item.statId == "separator": @["color"] else: @["icon", "name", "color"]
        for field in required:
            if not item.statArgs.hasKey(field):
                resolveError("$stats[" & $i & "] (@" & item.statId &
                             ") missing required field: " & field)
        if item.statArgs.hasKey("icon"):
            if item.statArgs["icon"].kind != cvChar:
                resolveError("$stats[" & $i & "] (@" & item.statId &
                             ") 'icon' must be a char literal (use single quotes)")
        if item.statArgs.hasKey("symbol"):
            if item.statArgs["symbol"].kind != cvChar:
                resolveError("$stats[" & $i & "] (@" & item.statId &
                             ") 'symbol' must be a char literal (use single quotes)")
        if item.statArgs.hasKey("name"):
            let nameKind = item.statArgs["name"].kind
            if nameKind notin {cvString, cvChar}:
                resolveError("$stats[" & $i & "] (@" & item.statId & ") 'name' must be a string")

    let distrosVal = output.vars["distros"]
    if distrosVal.kind != cvList:
        resolveError("$distros must be a list")
    for i, item in distrosVal.items:
        if item.kind != cvArt:
            resolveError("$distros[" & $i & "] must be an art block ({%name [...]})")
        if item.artNames.len == 0:
            resolveError("$distros[" & $i & "] must have at least one name")
        if item.art.len == 0:
            resolveError("$distros[" & $i & "] must have at least one art line")

#### Debug dump ####

proc dumpValue*(v: ConfigValue, indent: int = 0): string =
    let pad  = "  ".repeat(indent)
    let pad2 = "  ".repeat(indent + 1)
    case v.kind:
        of cvString:  pad & "String(\"" & v.strVal & "\")"
        of cvChar:    pad & "Char('"    & v.charVal & "')"
        of cvNumber:  pad & "Number("   & $v.numVal & ")"
        of cvBool:    pad & "Bool("     & $v.boolVal & ")"
        of cvHex:     pad & "Hex("      & v.hexVal & ")"
        of cvAnsi:    pad & "Ansi("     & v.ansiVal & ")"
        of cvRgb:     pad & "Rgb("      & $v.r & ", " & $v.g & ", " & $v.b & ")"
        of cvVarRef:  pad & "VarRef($"  & v.refName & ")  ← unresolved"
        of cvList:
            var s = pad & "List(\n"
            for item in v.items:
                s &= dumpValue(item, indent + 1) & "\n"
            s & pad & ")"
        of cvStat:
            var s = pad & "Stat(@" & v.statId & ")\n"
            for key, val in v.statArgs:
                s &= pad2 & key & " =\n"
                s &= dumpValue(val, indent + 2) & "\n"
            s.strip(trailing = true)
        of cvArt:
            var s = pad & "Art(" & v.artNames.join(", ") & ") margin=[" &
                    $v.margin[0] & " " & $v.margin[1] & " " & $v.margin[2] & "]\n"
            for line in v.art:
                s &= pad2 & "\"" & line & "\"\n"
            s.strip(trailing = true)
