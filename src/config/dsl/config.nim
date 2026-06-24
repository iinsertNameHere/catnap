import lexer
import parser
import analyzer
import tables
import "../../common/logging"
from "../types" import Config, StatEntry, MiscConfig, Logo

proc loadDslConfig*(src: string, baseDir: string = "."): DslOutput =
    try:
        let tokens = tokenize(src)
        let raw    = parse(tokens)
        let flat   = runImportPass(raw, baseDir)
        let cfg    = analyzeNodes(flat)
        result     = resolveDslOutput(cfg)
        validateDslOutput(result)
    except Exception as e:
        logError("config error: " & e.msg)
        quit(1)

proc dslToConfig*(output: DslOutput, configFile: string): Config =
    result.configFile = configFile

    for item in output.vars["stats"].items:
        var entry = StatEntry(id: item.statId)
        if item.statArgs.hasKey("icon"):   entry.icon   = valueToString(item.statArgs["icon"])
        if item.statArgs.hasKey("name"):   entry.name   = valueToString(item.statArgs["name"])
        if item.statArgs.hasKey("color"):  entry.color  = valueToString(item.statArgs["color"])
        if item.statArgs.hasKey("symbol"): entry.symbol = valueToString(item.statArgs["symbol"])
        result.stats.add(entry)

    for item in output.vars["distros"].items:
        let logo = Logo(margin: item.margin, art: item.art)
        for name in item.artNames:
            result.distroart[name] = logo

    result.misc.layout           = if output.vars.hasKey("layout"):           output.vars["layout"].strVal           else: "Inline"
    result.misc.borderstyle      = if output.vars.hasKey("borderstyle"):      output.vars["borderstyle"].strVal      else: "line"
    result.misc.stats_margin_top = if output.vars.hasKey("stats_margin_top"): output.vars["stats_margin_top"].numVal else: 0
    result.misc.location         = if output.vars.hasKey("location"):         output.vars["location"].strVal         else: ""
    result.misc.text_color       = if output.vars.hasKey("text_color"):       valueToString(output.vars["text_color"]) else: valueToString(output.vars["reset"])

proc dumpDslConfig*(cfg: DslOutput) =
    echo "=== Config ==="
    for name, val in cfg.vars:
        echo "$" & name & " ="
        echo dumpValue(val, indent = 1)
        echo ""
