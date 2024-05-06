# test help
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -h
# test distroid
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -d arch
# test grep
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -g kernel
# test margin
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -m 1,2,3
# test layout
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -l ArtOnTop
# test figletlogos mode
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -fe on
# test figletlogos margin
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -fe on -fm 1,2,3
# test figletlogos font
./../bin/catnip -c ../config/config.toml -a ../config/distros.toml -fe on -ff basic.flf
