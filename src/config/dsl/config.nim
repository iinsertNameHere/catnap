import lexer
import parser
import analyzer
import tables
import "../common/logging"

proc loadConfig*(src: string, baseDir: string = "."): Config =
    try:
        let tokens  = tokenize(src)
        let raw     = parse(tokens)
        let flat    = runImportPass(raw, baseDir)
        let cfg     = analyzeNodes(flat)
        result      = resolveConfig(cfg)
    except Exception as e:
        logError("config_error: " & e.msg)


proc dumpConfig*(cfg: Config) =
    echo "=== Config ==="
    for name, val in cfg.vars:
        echo "$" & name & " ="
        echo dumpValue(val, indent = 1)
        echo ""
