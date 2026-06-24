import strutils
import lexer

type NodeKind* = enum
    # Top-level
    nkImport      # import "file"
    nkVarAssign   # $var = <value>

    # Values
    nkString      # "hello"
    nkChar        # 'c'
    nkNumber      # 42
    nkBool        # true / false
    nkHex         # #cba6f7
    nkAnsi        # !31
    nkRgb         # (255 100 200)
    nkVarRef      # $name
    nkList        # [item item item]
    nkStatRef     # {@cpu key=val ...}
    nkArtBlock    # {%name1 %name2 ["line1" "line2"] margin=[1 2 3]}

    # Stat ref internals
    nkNamedArg    # key=value (only inside nkStatRef)

type Node* = ref object
    line*: int
    case kind*: NodeKind
        of nkImport:
            path*: string
        of nkVarAssign:
            varName*: string
            value*: Node
        of nkString:
            strVal*:  string
        of nkChar:
            charVal*: string
        of nkNumber:
            numVal*:  string
        of nkBool:
            boolVal*: bool
        of nkHex:
            hexVal*:  string
        of nkAnsi:
            ansiVal*: string
        of nkRgb:
            r*, g*, b*: int
        of nkVarRef:
            refName*: string
        of nkList:
            items*: seq[Node]
        of nkStatRef:
            statId*:    string
            namedArgs*: seq[Node]
        of nkArtBlock:
            artNames*:      seq[string]    # % prefixes stripped
            artLines*:      seq[Node]      # nkString nodes
            artMarginNode*: Node           # nkList of nkNumber, or nil
        of nkNamedArg:
            argKey*:   string
            argValue*: Node           # only scalar kinds

type Parser* = object
    tokens*: seq[Token]
    pos*:    int

type ParseError* = object of CatchableError

proc peek(p: Parser): Token =
    p.tokens[p.pos]

proc advance(p: var Parser): Token =
    result = p.tokens[p.pos]
    if result.kind != tkEof:
        inc p.pos

proc check(p: Parser, kind: TokenKind): bool =
    p.peek().kind == kind

proc expect(p: var Parser, kind: TokenKind): Token =
    if p.peek().kind != kind:
        raise newException(ParseError,
            "line " & $p.peek().line &
            ": expected " & $kind &
            " but got " & $p.peek().kind &
            " (" & p.peek().value & ")")
    p.advance()

proc skipNewlines(p: var Parser) =
    while p.peek().kind == tkNewLine:
        discard p.advance()

proc parseValue(p: var Parser): Node  # forward declaration

proc parseScalar(p: var Parser): Node =
    let tok = p.peek()
    case tok.kind:
        of tkString:  discard p.advance(); Node(kind: nkString, line: tok.line, strVal:  tok.value)
        of tkChar:    discard p.advance(); Node(kind: nkChar,   line: tok.line, charVal: tok.value)
        of tkNumber:  discard p.advance(); Node(kind: nkNumber, line: tok.line, numVal:  tok.value)
        of tkBool:    discard p.advance(); Node(kind: nkBool,   line: tok.line, boolVal: tok.value == "true")
        of tkHex:     discard p.advance(); Node(kind: nkHex,    line: tok.line, hexVal:  tok.value)
        of tkAnsi:    discard p.advance(); Node(kind: nkAnsi,   line: tok.line, ansiVal: tok.value)
        of tkVariable:discard p.advance(); Node(kind: nkVarRef, line: tok.line, refName: tok.value)
        of tkLParen:
            let line = tok.line
            discard p.advance()  # (
            let r = parseInt(expect(p, tkNumber).value)
            let g = parseInt(expect(p, tkNumber).value)
            let b = parseInt(expect(p, tkNumber).value)
            discard expect(p, tkRParen)
            Node(kind: nkRgb, line: line, r: r, g: g, b: b)
        else:
            raise newException(ParseError,
                "line " & $tok.line & ": unexpected token " & $tok.kind &
                " (" & tok.value & ")")

proc parseStatRef(p: var Parser): Node =
    let line = p.peek().line
    discard expect(p, tkLBrace)
    let statId = expect(p, tkStatId).value

    var namedArgs: seq[Node] = @[]
    while not p.check(tkRBrace) and not p.check(tkEof):
        let keyTok = expect(p, tkKey)
        discard expect(p, tkEquals)
        let val = p.parseScalar()
        namedArgs.add Node(kind: nkNamedArg, line: keyTok.line,
                        argKey: keyTok.value, argValue: val)

    discard expect(p, tkRBrace)
    Node(kind: nkStatRef, line: line, statId: statId, namedArgs: namedArgs)

proc parseArtBlock(p: var Parser): Node =
    let line = p.peek().line
    discard expect(p, tkLBrace)

    var artNames: seq[string] = @[]
    while p.check(tkArtId):
        artNames.add p.advance().value[1..^1]  # strip %

    if artNames.len == 0:
        raise newException(ParseError,
            "line " & $line & ": art block must have at least one %name")

    p.skipNewlines()
    var artLines: seq[Node] = @[]
    discard expect(p, tkLBracket)
    p.skipNewlines()
    while not p.check(tkRBracket) and not p.check(tkEof):
        let tok = p.peek()
        if tok.kind != tkString:
            raise newException(ParseError,
                "line " & $tok.line & ": art lines must be string literals")
        artLines.add Node(kind: nkString, line: tok.line, strVal: p.advance().value)
        p.skipNewlines()
    discard expect(p, tkRBracket)

    p.skipNewlines()
    var artMarginNode: Node = nil
    while p.check(tkKey):
        let keyTok = p.advance()
        discard expect(p, tkEquals)
        let val = p.parseValue()
        if keyTok.value == "margin":
            artMarginNode = val
        p.skipNewlines()

    discard expect(p, tkRBrace)
    Node(kind: nkArtBlock, line: line, artNames: artNames,
         artLines: artLines, artMarginNode: artMarginNode)

proc parseValue(p: var Parser): Node =
    case p.peek().kind:
        of tkLBrace:
            if p.pos + 1 < p.tokens.len and p.tokens[p.pos + 1].kind == tkArtId:
                p.parseArtBlock()
            else:
                p.parseStatRef()
        of tkLBracket:
            let line = p.peek().line
            discard p.advance()  # [
            var items: seq[Node] = @[]
            p.skipNewlines()
            while not p.check(tkRBracket) and not p.check(tkEof):
                items.add p.parseValue()
                p.skipNewlines()
            discard expect(p, tkRBracket)
            Node(kind: nkList, line: line, items: items)
        else:
            p.parseScalar()

proc parseImport(p: var Parser): Node =
    let line = p.peek().line
    discard expect(p, tkImport)
    let path = expect(p, tkString).value
    Node(kind: nkImport, line: line, path: path)

proc parseVarAssign(p: var Parser): Node =
    let tok = expect(p, tkVariable)
    discard expect(p, tkEquals)
    let val = p.parseValue()
    Node(kind: nkVarAssign, line: tok.line, varName: tok.value, value: val)

proc parseStatement(p: var Parser): Node =
    p.skipNewlines()
    case p.peek().kind:
        of tkImport:   p.parseImport()
        of tkVariable: p.parseVarAssign()
        of tkEof:      nil
        else:
            raise newException(ParseError,
                "line " & $p.peek().line & ": unexpected token at top level: " &
                $p.peek().kind & " (" & p.peek().value & ")")

proc parse*(tokens: seq[Token]): seq[Node] =
    var p = Parser(tokens: tokens, pos: 0)
    while not p.check(tkEof):
        p.skipNewlines()
        if p.check(tkEof): break
        result.add p.parseStatement()

proc dumpNode*(n: Node, indent: int = 0): string =
    if n == nil: return ""
    let pad = "  ".repeat(indent)
    case n.kind:
        of nkImport:    pad & "Import(" & n.path & ")"
        of nkVarAssign: pad & "VarAssign(" & n.varName & ")\n" & dumpNode(n.value, indent + 1)
        of nkString:    pad & "String(" & n.strVal & ")"
        of nkChar:      pad & "Char(" & n.charVal & ")"
        of nkNumber:    pad & "Number(" & n.numVal & ")"
        of nkBool:      pad & "Bool(" & $n.boolVal & ")"
        of nkHex:       pad & "Hex(" & n.hexVal & ")"
        of nkAnsi:      pad & "Ansi(" & n.ansiVal & ")"
        of nkRgb:       pad & "Rgb(" & $n.r & ", " & $n.g & ", " & $n.b & ")"
        of nkVarRef:    pad & "VarRef(" & n.refName & ")"
        of nkList:
            var s = pad & "List(\n"
            for item in n.items: s &= dumpNode(item, indent + 1) & "\n"
            s & pad & ")"
        of nkStatRef:
            var s = pad & "StatRef(" & n.statId & ")\n"
            for arg in n.namedArgs: s &= dumpNode(arg, indent + 1) & "\n"
            s
        of nkArtBlock:
            var s = pad & "ArtBlock(" & n.artNames.join(", ") & ")\n"
            for line in n.artLines: s &= dumpNode(line, indent + 1) & "\n"
            if n.artMarginNode != nil:
                s &= pad & "  margin=\n" & dumpNode(n.artMarginNode, indent + 2)
            s
        of nkNamedArg:
            pad & "NamedArg(" & n.argKey & "=)\n" & dumpNode(n.argValue, indent + 1)

proc dumpAst*(nodes: seq[Node]): string =
    echo "=== Ast ==="
    for node in nodes:
        echo dumpNode(node)
        echo ""
