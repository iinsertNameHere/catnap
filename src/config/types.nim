import tables

type
    Logo* = object
        margin*: array[3, int]
        art*:    seq[string]

    StatEntry* = object
        id*:     string
        icon*:   string
        name*:   string
        color*:  string    # resolved ANSI escape string
        symbol*: string    # only used by "colors" stat

    MiscConfig* = object
        layout*:           string
        borderstyle*:      string
        stats_margin_top*: int
        location*:         string
        text_color*:       string

    Config* = object
        configFile*: string
        stats*:      seq[StatEntry]
        distroart*:  OrderedTable[string, Logo]
        misc*:       MiscConfig
