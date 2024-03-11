<br />
<div align="center">
  <a href="https://github.com/iinsertNameHere/Catnip">
    <img src="image/logo.png" alt="Logo" width="200" height="200">
  </a>

<h3 align="center"><code>Catnip🌿</code> Systemfetch</h3>
  <p align="center">
    <a href="#-demo-image">View Demo</a>
    ·
    <a href="#-compilationinstallation-linux">Linux Installation</a>
    ·
    <a href="#-compilationinstallation-windows">Windows Installation</a>
  </p>
</div>
<br>

## 🌿 What is Catnip
I created `Catnip🌿` as a playful, simple system-information **concatenation** tool using `nim👑`. It is quite **customizable** and has possibilities to alter the names and colors of the statistics. In the future, I also intend to add more distribution logos. Feel free to contribute to the project at any time.

> #### ⏱️ Execution Time 
> *Around **0.009** seconds on my laptop*

### 📊 Displayed Statistics
- username
- hostname
- system uptime
- running os
- running kernel
- desktop env
- used shell
- terminal colors

## 📷 Demo Image
>**NOTE:** Design was inspired by <code><a href="https://github.com/ssleert/nitch">Nitch</a></code>

> <img width=500 src="image/demo.png">

## 💻 Usage
Run catnip in you terminal:
```bash
$ catnip
```

Change the distro icon using:
```bash
$ catnip -d <distro>
```

To get a full list of arguments use:
```bash
$ catnip --help
```

<details>
  <summary style="font-size: 18px; font-weight: 600;">Supported Distros</summary>
  <ul>
    <li>Arch</li>
    <li>Archcraft</li>
    <li>Ubuntu</li>
    <li>Debian</li>
    <li>LinuxMint</li>
    <li>NixOS</li>
    <li>Fedora</li>
    <li>Void</li>
    <li>Manjaro</li>
    <li>Windows</li>
  </ul>
</details>

## 🪡 Installation/Build

> **NOTE:* `pcre` has to be installed as a dependency.

**1.** Install <a href="https://nim-lang.org/install.html">`nim👑`</a>

**2.** Clone the repo:
```shell
git clone https://github.com/iinsertNameHere/catnip.git
```
**3.** Change dir to repo
```shell
cd ./catnip
```

**4.** Run setup using `nim👑`:
```shell
nim setup
```

**5.** Your compiled executable can be found in ./bin:
```shell
./bin/catnip
```

The config file can be found in your home directory under `.catnip/config.toml`

> **NOTE:** For the icons to work, make sure you set a [NerdFont](https://www.nerdfonts.com/) as you terminal font.

## 📒Configuration
The `stats` node is located in the config file (`.catnip/config.toml`).
You can change the names, colors, and icons for the various stats inside the `stats` node.

*Example config that dose not use NerdFont icons:* 
```toml
##############################################
##          FetchInfo stats Config          ##
##############################################
[stats]
username = {icon = ">", name = "user", color = "(RD)"}
hostname = {icon = ">", name = "hname", color = "(YW)"}
uptime   = {icon = ">", name = "uptime", color = "(BE)"}
distro   = {icon = ">", name = "distro", color = "(GN)"}
kernel   = {icon = ">", name = "kernel", color = "(MA)"}
desktop  = {icon = ">", name = "desktp", color = "(CN)"}
shell    = {icon = ">", name = "shell", color = "(RD)"}
colors   = {icon = ">", name = "colors", color = "!DT!", symbol = "#"}
```

### 🎨 Colors:
Catnip's color system uses a ColorId, witch is made up of the colors first and last letter, enclosed in characters that indicate the type of color.

**Color Types:**
- Forground Normal  -> `(#)`
- Forground Bright  -> `{#}`
- Background Normal -> `[#]`
- Background Bright -> `<#>`

>**NOTE:** `#` Should be replaced by the color id.

**Color IDs:**
- BLACK   -> `BK`
- RED     -> `RD`
- GREEN   -> `GN`
- YELLOW  -> `YW`
- BLUE    -> `BE`
- MAGENTA -> `MA`
- CYAN    -> `CN`
- WHITE   -> `WE`

So `{GN}` translates to: Forground-Bright-Green.
To set the color to Default, use `!DT!`.

## 🗃️ Todos
- [ ] Add more Distro logos
- [ ] Add config options for layout
- [ ] Add docs for how to define logos in the config file.
