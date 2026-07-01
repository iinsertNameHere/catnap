import lexer
import parser
import analyzer
import tables
import "../../common/logging"
from "../types" import Config, StatEntry, MiscConfig, Art

proc loadDslConfig*(src: string, baseDir: string = "."): DslOutput =
    try:
        let tokens = tokenize(src)
        let raw    = parse(tokens)
        let flat   = runImportPass(raw, baseDir)
        let cfg    = analyzeNodes(flat)
        result     = resolveDslOutput(cfg)
        validateWithSchema(result, buildSchema())
    except Exception as e:
        logError("config error: " & e.msg)
        quit(1)

proc dslToConfig*(output: DslOutput, configFile: string): Config =
    result.configFile = configFile

    for item in output.vars["stats"].items:
        let enabled = if item.statArgs.hasKey("enabled"): item.statArgs["enabled"].boolVal else: true
        if not enabled: continue

        if item.statId == "separator":
            result.stats.add(StatEntry(id: "separator"))
            continue

        var entry = StatEntry(id: item.statId)
        if item.statArgs.hasKey("icon"):   entry.icon   = valueToString(item.statArgs["icon"])
        if item.statArgs.hasKey("name"):   entry.name   = valueToString(item.statArgs["name"])
        if item.statArgs.hasKey("color"):  entry.color  = valueToString(item.statArgs["color"])
        if item.statArgs.hasKey("symbol"):      entry.symbol     = valueToString(item.statArgs["symbol"])
        if item.statArgs.hasKey("graph"):       entry.graph      = item.statArgs["graph"].boolVal
        if item.statArgs.hasKey("graph_style"): entry.graphStyle = item.statArgs["graph_style"].strVal else: entry.graphStyle = "precise"
        if item.statArgs.hasKey("graph_width"): entry.graphWidth = item.statArgs["graph_width"].numVal
        if item.statArgs.hasKey("graph_color_fg"): entry.graphFg = valueToString(item.statArgs["graph_color_fg"]) else: entry.graphFg = valueToString(output.vars["text_color"])
        if item.statArgs.hasKey("graph_color_bg"): entry.graphBg = valueToString(item.statArgs["graph_color_bg"]) else: entry.graphBg = valueToString(output.vars["text_color"])
        result.stats.add(entry)


    for item in output.vars["distros"].items:
        let art = Art(margin: item.margin, art: item.art)
        for name in item.artNames:
            result.distroart[name] = art

    result.misc.layout           = if output.vars.hasKey("layout"):           output.vars["layout"].strVal              else: "inline"
    result.misc.border_style     = if output.vars.hasKey("border_style"):     output.vars["border_style"].strVal        else: "single"
    result.misc.stats_margin_top = if output.vars.hasKey("stats_margin_top"): output.vars["stats_margin_top"].numVal else: 0
    result.misc.location         = if output.vars.hasKey("location"):         output.vars["location"].strVal         else: ""
    result.misc.text_color       = if output.vars.hasKey("text_color"):       valueToString(output.vars["text_color"])  else: valueToString(output.vars["reset"])
    result.misc.border_color     = if output.vars.hasKey("border_color"):     valueToString(output.vars["border_color"]) else: valueToString(output.vars["reset"])
    result.misc.graph_style      = if output.vars.hasKey("graph_style"):      output.vars["graph_style"].strVal          else: "precise"
    result.misc.graph_width      = if output.vars.hasKey("graph_width"):      output.vars["graph_width"].numVal          else: 15
    result.misc.graph_color_fg   = if output.vars.hasKey("graph_color_fg"):   valueToString(output.vars["graph_color_fg"]) else: ""
    result.misc.graph_color_bg   = if output.vars.hasKey("graph_color_bg"):   valueToString(output.vars["graph_color_bg"]) else: ""
    result.misc.distroid         = if output.vars.hasKey("distroid"):         output.vars["distroid"].strVal              else: ""


