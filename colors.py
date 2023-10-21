import re

BLACK   = "\u001b[30m" # (BK)
RED     = "\u001b[31m" # (RD)
GREEN   = "\u001b[32m" # (GN)
YELLOW  = "\u001b[33m" # (YW)
BLUE    = "\u001b[34m" # (BE)
MAGENTA = "\u001b[35m" # (MA)
CYAN    = "\u001b[36m" # (CN)
WHITE   = "\u001b[37m" # (WE)
DEFAULT = "\u001b[0m"  # (DT)

BRIGHT_BLACK   = "\u001b[1;30m" # [BK]
BRIGHT_RED     = "\u001b[1;31m" # [RD]
BRIGHT_GREEN   = "\u001b[1;32m" # [GN]
BRIGHT_YELLOW  = "\u001b[1;33m" # [YW]
BRIGHT_BLUE    = "\u001b[1;34m" # [BE]
BRIGHT_MAGENTA = "\u001b[1;35m" # [MA]
BRIGHT_CYAN    = "\u001b[1;36m" # [CN]
BRIGHT_WHITE   = "\u001b[1;37m" # [WE]

COLOR = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')

def colorize(uncolored: str) -> str:
    colored = uncolored \
        .replace("(BK)", BLACK).replace("[BK]", BRIGHT_BLACK) \
        .replace("(RD)", RED).replace("[RD]", BRIGHT_RED) \
        .replace("(GN)", GREEN).replace("[GN]", BRIGHT_GREEN) \
        .replace("(YW)", YELLOW).replace("[YW]", BRIGHT_YELLOW) \
        .replace("(BE)", BLUE).replace("[BE]", BRIGHT_BLUE) \
        .replace("(MA)", MAGENTA).replace("[MA]", BRIGHT_MAGENTA) \
        .replace("(CN)", CYAN).replace("[CN]", BRIGHT_CYAN) \
        .replace("(WE)", WHITE).replace("[WE]", BRIGHT_WHITE) \
        .replace("(DT)", DEFAULT)
    return colored

def uncolorize(colored: str) -> str:
    uncolored = COLOR.sub('', colored)
    return uncolored
