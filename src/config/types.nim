import tables

type
    Logo* = object
        margin*: array[3, int]
        art*:    seq[string]

    StatEntry* = object
        id*:         string
        icon*:       string
        name*:       string
        color*:      string
        symbol*:     string
        graph*:      bool
        graphStyle*: string
        graphWidth*: int
        graphFg*:    string
        graphBg*:    string

    MiscConfig* = object
        layout*:           string
        border_style*:     string
        border_color*:     string
        stats_margin_top*: int
        location*:         string
        text_color*:       string
        graph_style*:      string
        graph_width*:      int
        graph_color_fg*:    string
        graph_color_bg*:    string

    Config* = object
        configFile*: string
        stats*:      seq[StatEntry]
        distroart*:  OrderedTable[string, Logo]
        misc*:       MiscConfig
