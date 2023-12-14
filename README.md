<br />
<div align="center">
  <a href="https://github.com/iinsertNameHere">
    <img src="image/logo.png" alt="Logo" width="200" height="200">
  </a>

<h3 align="center">Catnip Systemfetch</h3>
  <p align="center">
    <a href="https://github.com/github_username/repo_name">View Demo</a>
    ·
    <a href="https://github.com/github_username/repo_name/issues">Report Bug</a>
    ·
    <a href="https://github.com/github_username/repo_name/issues">Request Feature</a>
  </p>
</div>
<br>

## What is Catnip

![demoimage](image/demo.png)

I created Catnip as a playful, simple system-information **concatenation** tool in **nim**. It is quite **customizable** and has possibilities to alter the names and colors of the statistics. In the future, I also intend to add more distribution logos. Feel free to contribute to the project at any time.

### Displayed Statistics
- username
- hostname
- system uptime
- running os
- running kernel
- desktop env
- used shell
- terminal colors

>**NOTE:** Design was inspired by [Nitch](https://github.com/ssleert/nitch)

## Usage
Run catnip in you terminal:
```bash
./catnip
```

Change the distro icon using:
```bash
./catnip [distroname]
```


##  Compilation/Installation
Install nim with you favorit pkg manager:
```bash
sudo yay -S nim
```

Clone the repo:
```bash
git clone https://github.com/iinsertNameHere/Catnip.git
cd ./Catnip/src
```

Run nim compilation:
```bash
nim c -d:release catnip.nim
```

Copy config:
>**NOTE:** For the icons to work, make sure you set a [NerdFont](https://www.nerdfonts.com/) as you terminal font.
```bash
cp ../catnip.json ~/.config/catnip.json
```

## Todos
- [ ] Add more Distro logos
- [X] Add config options for icons
- [X] Add more config options for colors
- [ ] Make Catnip crossplatform
- [ ] Add config options for layout