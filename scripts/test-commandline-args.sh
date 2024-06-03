# Test Normal run
echo "[!] Testing: Normal Run"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml

# Test help
echo "[!] Testing: Help"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -h

# Test version
echo "[!] Testing: Version"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -v

# Test distroid
echo "[!] Testing: DistroId"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -d arch

# Test grep
echo "[!] Testing: Grep"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -g kernel

# Test margin
echo "[!] Testing: Margin"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -m 1,2,3

# Test layout
echo "[!] Testing: Layout"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -l ArtOnTop

# Test figletlogos mode
echo "[!] Testing: FigletLogos"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -fe on

# Test figletlogos margin
echo "[!] Testing: FigletLogos Margin"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -fe on -fm 1,2,3

# Test figletlogos font with example figlet font file
echo "[!] Testing: FigletLogos Font"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -fe on -ff basic.flf

# Test default Config
echo "[!] Testing: Default config"
./../bin/catnap -c ../config/config.toml -a ../config/distros.toml