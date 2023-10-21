from functools import cache, wraps
import platform
import time
import os
import subprocess
import re
import json
from argparse import ArgumentParser

BLACK:          str = "\u001b[30m" # (BK)
RED:            str = "\u001b[31m" # (RD)
GREEN:          str = "\u001b[32m" # (GN)
YELLOW:         str = "\u001b[33m" # (YW)
BLUE:           str = "\u001b[34m" # (BE)
MAGENTA:        str = "\u001b[35m" # (MA)
CYAN:           str = "\u001b[36m" # (CN)
WHITE:          str = "\u001b[37m" # (WE)
DEFAULT:        str = "\u001b[0m"  # (DT)
BRIGHT_BLACK:   str = "\u001b[1;30m" # [BK]
BRIGHT_RED:     str = "\u001b[1;31m" # [RD]
BRIGHT_GREEN:   str = "\u001b[1;32m" # [GN]
BRIGHT_YELLOW:  str = "\u001b[1;33m" # [YW]
BRIGHT_BLUE:    str = "\u001b[1;34m" # [BE]
BRIGHT_MAGENTA: str = "\u001b[1;35m" # [MA]
BRIGHT_CYAN:    str = "\u001b[1;36m" # [CN]
BRIGHT_WHITE:   str = "\u001b[1;37m" # [WE]

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

def get_uptime():
    t = time.clock_gettime(time.CLOCK_BOOTTIME)
    m, _ = divmod(t, 60)
    h, m = divmod(m, 60)
    d, h = divmod(h, 24)

    d, h, m = [int(d), int(h), int(m)]
    return (f"{d}d " if d else "") + (f"{h}h " if h else "") + f"{m}m"

def get_processor() -> str:
    if platform.system() == "Windows":
        return platform.processor()

    elif platform.system() == "Darwin":
        os.environ['PATH'] = os.environ['PATH'] + os.pathsep + '/usr/sbin'
        command: str ="sysctl -n machdep.cpu.brand_string"
        return subprocess.check_output(command).decode().strip()

    elif platform.system() == "Linux":
        command: str = "cat /proc/cpuinfo"
        all_info: str = subprocess.check_output(command, shell=True).decode().strip()

        for line in all_info.split("\n"):
            if "model name" in line:
                return re.sub( ".*model name.*:", "", line,1)
    return "Null"

def realLen(line):
    if line:
        uncolored_Line = uncolorize(line)
        return len(uncolored_Line)
    return 0

class FetchInfo:
    def __init__(self,
    distro_file:        str = "distros.json",
    distro_name:        str|None = None,
    distro_suffix: str = str(),
    color:              str = BRIGHT_CYAN):
        self.distro_file = distro_file
        self.distro_suffix = distro_suffix
        self.distro_name = distro_name
        self.color = color

        self.username:     str = os.getlogin()
        self.hostname:     str = os.uname()[1]
        self.archetecture: str = os.uname()[4]
        self.os:           str = platform.freedesktop_os_release()['NAME']
        self.kernel:       str = platform.system().lower() + "-" + platform.release()
        self.desktop:      str = os.environ.get("XDG_SESSION_DESKTOP", "Null")
        self.terminal:     str = os.environ.get("TERM", "Null")

        shell:             list = os.environ.get("SHELL", "Null").replace("\\", "/").split("/")
        self.shell:        str  = shell[len(shell)-1] if len(shell) else "Null"

        self.cpu:          str = get_processor()
        self.uptime:       str = get_uptime()

        self.art:          list[str]
        self.art_len:      int
        self.art_lines:    int

        self.top:          int
        self.bottom:       int
        self.left:         int
        self.right:        int

    def get_distro(self) -> dict:
        name: str = self.os.lower() + self.distro_suffix

        if self.distro_name:
            name = self.distro_name + self.distro_suffix

        with open(self.distro_file, 'r') as f:
            distros = json.load(f)

        default = distros.get("default")
        if not default:
            print("# Failed to load distros!")
            exit(1)
        
        distro = distros.get(name, default)

        alias = distro.get("alias")
        while alias:
            distro = distros.get(alias, default)
            alias = distro.get("alias", "")
        
        art = distro.get("art", [])
        distro["art"] = []

        for line in art:
            distro["art"].append(colorize(line))
        
        return distro

    def formateLine(self, line: str) -> str:
        res = (" "*self.left + ((self.art[self.art_index] if self.art_index < self.art_lines else " "*self.art_len)) + " "*self.right + line)
        self.top -= 1
        self.art_index += 1
        return res

    def __repr__(self):
        rep: list[str] = []
        
        distro = self.get_distro()

        self.art = distro.get("art", [])
        self.art_index = 0
        self.art_len = realLen(self.art[0])


        self.top, self.bottom, self.left, self.right = distro.get("margin", [0, 0, 0, 0])

        for i in range(0, self.top):
            self.art = [" "*self.art_len] + self.art

        self.art_lines = len(self.art)

        for i in range(0, self.bottom):
            rep.append(" " * self.left + (self.art[self.art_index] if self.art_index < self.art_lines else " "*self.art_len))
            self.art_index += 1

        rep.append(self.formateLine(f"{self.color}{self.username}\033[0m@{self.color}{self.hostname}\033[0m"))
        rep.append(self.formateLine(self.color+"-"*(realLen(rep[len(rep)-1])-self.art_len)))
        rep.append(self.formateLine(f"{self.color}Uptime: \033[0m{self.uptime}"))
        rep.append(self.formateLine(self.color+"-"*(realLen(rep[len(rep)-1])-self.art_len)))
        rep.append(self.formateLine(f"{self.color}OS: \033[0m{self.os} {self.archetecture}"))
        rep.append(self.formateLine(f"{self.color}Kernel: \033[0m{self.kernel}"))
        rep.append(self.formateLine(f"{self.color}CPU: \033[0m{self.cpu}"))
        rep.append(self.formateLine(f"{self.color}Terminal: \033[0m{self.terminal}"))
        rep.append(self.formateLine(f"{self.color}Desktop: \033[0m{self.desktop}"))
        rep.append(self.formateLine(f"{self.color}Shell: \033[0m{self.shell}"))

        line = f"{self.color}--------------"
        last_len = (realLen(rep[len(rep)-1])-self.art_len)
        rep.append(self.formateLine((line if last_len < len(line) else self.color+"-"*last_len)))

        rep.append(self.formateLine(f"{BRIGHT_BLUE}⬤   {BRIGHT_GREEN}⬤   {BRIGHT_RED}⬤   {BRIGHT_YELLOW}⬤"))

        while self.art_index < self.art_lines:
            rep.append(" "*self.left + self.art[self.art_index])
            self.art_index += 1

        return "\n".join(rep)

def get_time():
    return time.time_ns() // 1_000_000

if __name__ == "__main__":
    start = get_time()
    
    parser = ArgumentParser()
    parser.add_argument("-d", "--distro", required= False, default=None, help="Changes the distro art that is displayed")
    parser.add_argument("-s", "--small", required=False, action="store_true", default=False, help="Uses the small distro art version if posible")
    args = parser.parse_args()

    info = FetchInfo(
        distro_file=f"distros.json",
        distro_name=args.distro,
        distro_suffix="_small" if args.small else ""
    )
    print(info)

    print(f"{DEFAULT}Finished after {get_time() - start}ms")