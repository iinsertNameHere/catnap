# Test Normal run
echo "[!] Testing: Normal Run"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml

# Test help
echo "[!] Testing: Help"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -h

# Test version
echo "[!] Testing: Version"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -v

# Test distroid
echo "[!] Testing: DistroId"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -d arch

# Test grep
echo "[!] Testing: Grep"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -g kernel

# Test margin
echo "[!] Testing: Margin"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -m 1,2,3

# Test layout
echo "[!] Testing: Layout"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -l ArtOnTop

# Test figletlogos mode
echo "[!] Testing: FigletLogos"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -fe on

# Test figletlogos margin
echo "[!] Testing: FigletLogos Margin"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -fe on -fm 1,2,3

# Test figletlogos font with example figlet font file
echo "[!] Testing: FigletLogos Font"
./../bin/catnip -c ./test_config.toml -a ../config/distros.toml -fe on -ff basic.flf

# Test default Config
echo "[!] Testing: Default config"
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml