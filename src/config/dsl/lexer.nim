import strutils


type TokenKind* = enum
    # Literals
    tkString      # "hello"
    tkChar        # 'c'
    tkNumber      # 10
    tkBool        # true / false
    tkHex         # #cba6f7
    tkAnsi        # !31
    # Identifiers
    tkVariable    # $name
    tkKey         # bar, color, enabled... (bare word before =)

    # Sigils
    tkAt          # @
    tkPercent     # %

    # Structure
    tkImport      # import
    tkEquals      # =
    tkLBracket    # [
    tkRBracket    # ]
    tkLBrace      # {
    tkRBrace      # }
    tkLParen      # (
    tkRParen      # )
    tkNewLine
    tkEof

type Token* = object
    kind*: TokenKind
    value*: string
    line*: int

type Lexer* = object
    src*: string
    pos*: int
    line*: int

proc peek(l: Lexer): char =
    if l.pos < l.src.len: l.src[l.pos] else: '\0'

proc advance(l: var Lexer): char =
    result = l.src[l.pos]
    inc l.pos
    if result == '\n': inc l.line

proc skipWhitespaceAndComments(l: var Lexer) =
    while l.pos < l.src.len:
        case l.peek():
            of ' ', '\t', '\r':
                discard l.advance()
            of ';':
                if l.pos + 1 < l.src.len and l.src[l.pos + 1] == '*':
                    discard l.advance(); discard l.advance()  # consume ;*
                    while l.pos + 1 < l.src.len:
                        if l.peek() == '*' and l.src[l.pos + 1] == ';':
                            discard l.advance(); discard l.advance()  # consume *;
                            break
                        discard l.advance()
                else:
                    while l.pos < l.src.len and l.peek() != '\n':
                        discard l.advance()
            else: break

proc lexString(l: var Lexer): Token =
    discard l.advance()  # opening "
    var buf = ""
    while l.pos < l.src.len and l.peek() != '"':
        let c = l.advance()
        if c == '\\' and l.pos < l.src.len:
            buf.add l.advance()
        else:
            buf.add c
    discard l.advance()  # closing "
    Token(kind: tkString, value: buf)

proc lexChar(l: var Lexer): Token =
    discard l.advance()  # opening '
    var buf = ""
    if l.peek() == '\\':
        discard l.advance()
        buf.add l.advance()
    else:
        while l.pos < l.src.len and l.peek() != '\'':
            buf.add l.advance()
    discard l.advance()  # closing '
    Token(kind: tkChar, value: buf)

proc lexHex(l: var Lexer): Token =
    discard l.advance()  # consume '#'
    var buf = "#"
    while l.pos < l.src.len and l.peek() in HexDigits:
        buf.add l.advance()
    Token(kind: tkHex, value: buf)

proc lexAnsi(l: var Lexer): Token =
    discard l.advance()  # consume !
    var buf = "!"
    while l.pos < l.src.len and l.peek().isDigit():
        buf.add l.advance()
    Token(kind: tkAnsi, value: buf)

proc lexVariable(l: var Lexer): Token =
    discard l.advance()  # consume $
    var buf = "$"
    while l.pos < l.src.len and (l.peek().isAlphaAscii() or l.peek() in {'_', '0'..'9'}):
        buf.add l.advance()
    Token(kind: tkVariable, value: buf)

proc lexNumber(l: var Lexer): Token =
    var buf = ""
    while l.pos < l.src.len and l.peek().isDigit():
        buf.add l.advance()
    Token(kind: tkNumber, value: buf)

proc lexBareWord(l: var Lexer): Token =
    var buf = ""
    while l.pos < l.src.len and (l.peek().isAlphaAscii() or l.peek() in {'_', '0'..'9'}):
        buf.add l.advance()
    let kind = case buf
        of "import":        tkImport
        of "true", "false": tkBool
        else:               tkKey
    Token(kind: kind, value: buf)

proc nextToken*(l: var Lexer): Token =
    l.skipWhitespaceAndComments()
    let startLine = l.line

    if l.pos >= l.src.len:
        return Token(kind: tkEof, value: "", line: startLine)

    case l.peek():
        of '"':  result = l.lexString()
        of '\'': result = l.lexChar()
        of '#':  result = l.lexHex()
        of '!':  result = l.lexAnsi()
        of '$':  result = l.lexVariable()
        of '@':  discard l.advance(); result = Token(kind: tkAt,      value: "@")
        of '%':  discard l.advance(); result = Token(kind: tkPercent,  value: "%")
        of '=':  discard l.advance(); result = Token(kind: tkEquals,   value: "=")
        of '[':  discard l.advance(); result = Token(kind: tkLBracket, value: "[")
        of ']':  discard l.advance(); result = Token(kind: tkRBracket, value: "]")
        of '{':  discard l.advance(); result = Token(kind: tkLBrace,   value: "{")
        of '}':  discard l.advance(); result = Token(kind: tkRBrace,   value: "}")
        of '(':  discard l.advance(); result = Token(kind: tkLParen,   value: "(")
        of ')':  discard l.advance(); result = Token(kind: tkRParen,   value: ")")
        of '\n': discard l.advance(); result = Token(kind: tkNewLine,  value: "\\n")
        elif l.peek().isDigit(): result = l.lexNumber()
        else:    result = l.lexBareWord()
    result.line = startLine

proc tokenize*(src: string): seq[Token] =
    var l = Lexer(src: src, pos: 0, line: 1)
    while true:
        let tok = l.nextToken()
        result.add tok
        if tok.kind == tkEof: break

proc dumpTokens*(tokens: seq[Token]) =
    echo "=== Tokens ==="
    for tok in tokens:
        echo alignLeft($tok.kind, 16) & " | " & alignLeft(tok.value, 20) & " | line " & $tok.line
