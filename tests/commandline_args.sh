# Test help
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -h

# Test version
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -v

# Test distroid
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -d arch

# Test grep
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -g kernel

# Test margin
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -m 1,2,3

# Test layout
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -l ArtOnTop

# Test figletlogos mode
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -fe on

# Test figletlogos margin
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -fe on -fm 1,2,3

# Test figletlogos font with example figlet font file
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -fe on -ff basic.flf
