import platform
import time
import os
import subprocess
import re
import json
from argparse import ArgumentParser
import colors

class FetchInfo:
    def __init__(self, distro_name = None, distro_name_suffix = "", color = colors.BRIGHT_CYAN):
        self.distro_name_suffix = distro_name_suffix
        self.distro_name = distro_name
        self.color = color

        self.username:    str = platform.os.getlogin()
        self.hostname:    str = platform.os.uname()[1]
        self.archetecute: str = platform.os.uname()[4]
        self.os:          str = platform.freedesktop_os_release()['NAME']
        self.kernel:      str = "%s-%s" % (platform.system().lower(), platform.release())
        self.desktop:     str = platform.os.environ.get("XDG_SESSION_DESKTOP", "Null")
        self.terminal:    str = platform.os.environ.get("TERM", "Null")

        self.shell:       list = platform.os.environ.get("SHELL", "Null").replace("\\", "/").split("/")
        self.shell:       str  = self.shell[len(self.shell)-1] if len(self.shell) else "Null"

        self.cpu:         str = self.get_processor()
        self.uptime:      str = self.get_uptime()

        self.art_len = 0

    def get_processor(self):
        if platform.system() == "Windows":
            return platform.processor()
        elif platform.system() == "Darwin":
            os.environ['PATH'] = os.environ['PATH'] + os.pathsep + '/usr/sbin'
            command ="sysctl -n machdep.cpu.brand_string"
            return subprocess.check_output(command).strip()
        elif platform.system() == "Linux":
            command = "cat /proc/cpuinfo"
            all_info = subprocess.check_output(command, shell=True).decode().strip()
            for line in all_info.split("\n"):
                if "model name" in line:
                    return re.sub( ".*model name.*:", "", line,1)
        return "Null"

    def get_uptime(self):
        t = time.clock_gettime(time.CLOCK_BOOTTIME)
        m, _ = divmod(t, 60)
        h, m = divmod(m, 60)
        d, h = divmod(h, 24)

        d, h, m = [int(d), int(h), int(m)]
        return (f"{d}d " if d else "") + (f"{h}h " if h else "") + f"{m}m"

    def realLen(self, line):
        if line:
            uncolored_Line = colors.uncolorize(line)
            return len(uncolored_Line)
        return 0

    def get_distro(self) -> list[str]:
        name = self.os.lower() + self.distro_name_suffix

        if self.distro_name:
            name = self.distro_name + self.distro_name_suffix

        with open("distros.json", 'r') as f:
            distros = json.load(f)

        default = distros.get("default")
        if default is None:
            print("# Failed to load distros!")
            exit(1)
        
        distro = distros.get(name, default)

        alias = distro.get("alias")
        while alias:
            distro = distros.get(alias, default)
            alias = distro.get("alias")
        
        art = distro["art"]
        distro["art"] = []

        for line in art:
            distro["art"].append(colors.colorize(line))
        
        return distro

    def formateLine(self, line: str) -> str:
        res = (" "*self.left + ((self.art[self.art_index] if self.art_index < self.art_lines else " "*self.art_len)) + " "*self.right + line)
        self.top -= 1
        self.art_index += 1
        return res

    def __repr__(self):
        rep: list[str] = []
        
        distro = self.get_distro()

        if distro is None:
            distro = distros.get("default")

        self.art = distro.get("art")
        self.art_index = 0
        self.art_len = self.realLen(self.art[0])


        self.top, self.bottom, self.left, self.right = distro["margin"]

        for i in range(0, self.top):
            self.art = [" "*self.art_len] + self.art

        self.art_lines = len(self.art)

        for i in range(0, self.bottom):
            rep.append(" " * self.left + (self.art[self.art_index] if self.art_index < self.art_lines else " "*self.art_len))
            self.art_index += 1

        rep.append(self.formateLine(f"{self.color}{self.username}\033[0m@{self.color}{self.hostname}\033[0m"))
        rep.append(self.formateLine(self.color+"-"*(self.realLen(rep[len(rep)-1])-self.art_len)))
        rep.append(self.formateLine(f"{self.color}Uptime: \033[0m{self.uptime}"))
        rep.append(self.formateLine(self.color+"-"*(self.realLen(rep[len(rep)-1])-self.art_len)))
        rep.append(self.formateLine(f"{self.color}OS: \033[0m{self.os} {self.archetecute}"))
        rep.append(self.formateLine(f"{self.color}Kernel: \033[0m{self.kernel}"))
        rep.append(self.formateLine(f"{self.color}CPU: \033[0m{self.cpu}"))
        rep.append(self.formateLine(f"{self.color}Terminal: \033[0m{self.terminal}"))
        rep.append(self.formateLine(f"{self.color}Desktop: \033[0m{self.desktop}"))
        rep.append(self.formateLine(f"{self.color}Shell: \033[0m{self.shell}"))

        line = f"{self.color}--------------"
        last_len = (self.realLen(rep[len(rep)-1])-self.art_len)
        rep.append(self.formateLine((line if last_len < len(line) else self.color+"-"*last_len)))

        rep.append(self.formateLine(f"{colors.BRIGHT_BLUE}⬤   {colors.BRIGHT_GREEN}⬤   {colors.BRIGHT_RED}⬤   {colors.BRIGHT_YELLOW}⬤"))

        while self.art_index < self.art_lines:
            rep.append(" "*self.left + self.art[self.art_index])
            self.art_index += 1

        return "\n".join(rep)

    def asDict(self):
        return {
            "username":     self.username,
            "hostname":     self.hostname,
            "archetecture": self.archetecture,
            "os":           self.os,
            "kernel":       self.kernel,
            "desktop":      self.desktop,
            "terminal":     self.terminal,
            "shell":        self.shell,
            "cpu":          self.cpu,
            "uptime":       self.uptime
        }

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-d", "--distro", required= False, default=None, help="Changes the distro art that is displayed")
    parser.add_argument("-s", "--small", required=False, action="store_true", default=False, help="Uses the small distro art version if posible")
    args = parser.parse_args()
    info = FetchInfo(distro_name=args.distro, distro_name_suffix="_small" if args.small else "")
    print(info)