function VerifyTest() {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

#### TESTS ####

# Test Normal run
echo "[!] Testing: Normal Run"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -n
VerifyTest

# Test help
echo "[!] Testing: Help"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -h -n
VerifyTest

# Test version
echo "[!] Testing: Version"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -v -n
VerifyTest

# Test distroid
echo "[!] Testing: DistroId"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -d arch -n
VerifyTest

# Test grep
echo "[!] Testing: Grep"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -g kernel -n
VerifyTest

# Test margin
echo "[!] Testing: Margin"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -m 1,2,3 -n
VerifyTest

# Test layout
echo "[!] Testing: Layout"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -l ArtOnTop -n
VerifyTest

# Test figletlogos mode
echo "[!] Testing: FigletLogos"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -fe on -n
VerifyTest

# Test figletlogos margin
echo "[!] Testing: FigletLogos Margin"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -fe on -fm 1,2,3 -n
VerifyTest

# Test figletlogos font with example figlet font file
echo "[!] Testing: FigletLogos Font"
./../bin/catnap -c ./test_config.toml -a ../config/distros.toml -fe on -ff basic.flf -n
VerifyTest

# Test default Config
echo "[!] Testing: Default config"
./../bin/catnap -c ../config/config.toml -a ../config/distros.toml -n
VerifyTest

