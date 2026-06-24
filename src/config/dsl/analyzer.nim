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
    cvHex       # #cba6f7
    cvAnsi      # !31
    cvRgb       # (r, g, b)
    cvList
    cvStat
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
    of cvVarRef:  refName*: string

type Config* = object
    vars*: Table[string, ConfigValue]   # keyed without leading $

type AnalyzeError* = object of CatchableError
type ResolveError* = object of CatchableError

#### Helpers ####

proc analyzeError(line: int, msg: string) =

    raise newException(AnalyzeError, "line " & $line & ": " & msg)

proc resolveError(msg: string) =
    raise newException(ResolveError, msg)

proc fmtCycle(chain: seq[string]): string =
    chain.join(" -> ") & " -> " & chain[0]

# #### Import pre-pass ####

# Walks the top-level node list and replaces every nkImport with the parsed
# nodes from that file. The result is a flat seq[Node] with no nkImport left.
# Import paths are resolved relative to `baseDir`.
# `visiting` holds the canonicalized paths currently on the call stack so
# circular imports (a imports b imports a) are caught.

proc runImportPass*(nodes: seq[Node], baseDir: string,
                    visiting: var seq[string]): seq[Node] =
    for n in nodes:
        if n == nil: continue
        if n.kind == nkImport:
            let path = expandFilename(baseDir / n.path)
            if not fileExists(path):
                analyzeError(n.line, "imported file not found: " & path)

            # Circular import check
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

#### Analyze pass ####
#
# Converts AST nodes to ConfigValues. VarRefs are left as cvVarRef.

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

proc analyzeValue(n: Node, inStatArg: bool = false): ConfigValue =
    case n.kind:
        of nkString, nkChar, nkNumber, nkBool, nkHex, nkAnsi, nkRgb, nkVarRef:
            analyzeScalar(n)

        of nkList:
            if inStatArg:
                # Flat list only
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

        else:
            analyzeError(n.line, "unexpected node kind in value position: " & $n.kind)
            nil

proc analyzeNodes*(nodes: seq[Node]): Config =
    result.vars = initTable[string, ConfigValue]()
    for n in nodes:
        if n == nil: continue
        case n.kind:
            of nkVarAssign:
                let name = n.varName[1..^1]  # strip $
                result.vars[name] = analyzeValue(n.value)
            of nkImport:
                # Should not appear after the import pre-pass
                analyzeError(n.line, "unexpected import node during analyze (import pre-pass skipped?)")
            else:
                analyzeError(n.line, "unexpected top-level node: " & $n.kind)

#### Resolution pass ####

# Replaces every cvVarRef with the actual value from the symbol table.
# Hard errors on undefined names or circular references ($a = $b, $b = $a).

proc resolveValue(v: ConfigValue, env: Table[string, ConfigValue],
                  visiting: var seq[string]): ConfigValue

proc resolveValue(v: ConfigValue, env: Table[string, ConfigValue],
                  visiting: var seq[string]): ConfigValue =
    case v.kind:
        of cvVarRef:
            let name = v.refName
            if not env.hasKey(name):
                resolveError("undefined variable: $" & name)

            # Circular reference check
            if name in visiting:
                let cycle = visiting[visiting.find(name)..^1]
                resolveError("circular variable reference: " & fmtCycle(cycle))

            visiting.add name
            result = resolveValue(env[name], env, visiting)
            discard visiting.pop()

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

        else:
            result = v  # scalars are already fully resolved

proc resolveConfig*(cfg: Config): Config =
    result.vars = initTable[string, ConfigValue]()
    for name, val in cfg.vars:
        var visiting: seq[string] = @[name]
        result.vars[name] = resolveValue(val, cfg.vars, visiting)

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
