# How to contribute
Create a new [issue](https://github.com/iinsertNameHere/catnip/issues) using the correct issue template or introduce a new feature/fix a bug and submit a pull request.

# Project structure
```graphql
.
├── config/
│   ├── config.toml  # Main config
│   └── distros.toml # Distro art config
├── docs/  # Contains man docs
├── image/ # Contains all images for README.md
├── src/
│   ├── catniplib/
│   │   ├── drawing/    # Files for rendering output
│   │   ├── generation/ # Files for generating output objects
│   │   ├── global/     # Files used globally
│   │   ├── platform/   # Files related to fetching system info
│   │   └── terminal/   # Files related to terminal stuff (Colors, Logging)
│   ├── extern/
│   │   ├── headers/   # Contains extern c++ headers (hpp)
│   │   └── libraries/ # Contains extern libs
│   └── catnip.nim # Entry src file
├── scripts/
│   ├── test-commandline-args.sh # Checks if catnip's cmd args work
│   └── git-commit-id.sh         # Generates the currentcommit.nim file
└── config.nims
```

# How to add a new distro

1. Add the distro's logo in the default `distros.toml` in the `config/` folder. Please arrange the distro in alphabetical order.
2. In `src/catniplib/global/definitions.nim`, go to the `PKGMANAGERS` section.
3. According to the name of the distro in `config/distros.toml`, put a new line like this:
```nim
"name of distro": "name of package manager",
```
4. If your distro's package manager is already in the `PKGCOUNTCOMMANDS` section, skip the next step.
5. Put your distro's package manager in the `PKGCOUNTCOMMANDS` section like this:
```nim
"name of package manager": "command to get number of packages",
```
6. Submit a pull request to the Catnip repo.
