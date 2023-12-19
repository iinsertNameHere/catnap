<br />
<div align="center">
  <a href="https://github.com/iinsertNameHere/Catnip">
    <img src="image/logo.png" alt="Logo" width="200" height="200">
  </a>

<h3 align="center">Catnip Systemfetch</h3>
  <p align="center">
    <a href="#demo-image">View Demo</a>
    ·
    <a href="https://github.com/iinsertNameHere/Catnip/issues">Report Bug</a>
    ·
    <a href="https://github.com/iinsertNameHere/Catnip/issues">Request Features</a>
  </p>
</div>
<br>

## What is Catnip

I created Catnip as a playful, simple system-information **concatenation** tool using **nim**. It is quite **customizable** and has possibilities to alter the names and colors of the statistics. In the future, I also intend to add more distribution logos. Feel free to contribute to the project at any time.

> #### Execution Time 
> *Around **0.0008** seconds on my laptop*

### Displayed Statistics
- username
- hostname
- system uptime
- running os
- running kernel
- desktop env
- used shell
- terminal colors

## Demo Image
>**NOTE:** Design was inspired by [Nitch](https://github.com/ssleert/nitch)

> <img width=500 src="image/demo.png">

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