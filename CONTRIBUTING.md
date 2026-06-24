# How to contribute
Create a new [issue](https://github.com/iinsertNameHere/catnap/issues) using the correct issue template or introduce a new feature/fix a bug and submit a pull request.

Catnap uses [Semantic Versioning](https://semver.org/), make sure to bump the version respectively.

To bump the version, use the `versionctl` tool which can be generated using:
```shell
# Generate versionctl tool
$ nim generate_versionctl

# List usage of versionctl tool
$ versionctl
```

# Project structure
```graphql
.
├── config/
│   ├── config.toml  # Main config
│   └── distros.toml # Distro art config
├── docs/  # Contains man docs
├── image/ # Contains all images for README.md
├── src/
│   ├── common/     # Layer 1 => no internal deps; stdlib only
│   ├── config/     # Layer 2 => depends on: common
│   ├── system/     # Layer 3 => depends on: common, config
│   ├── generation/ # Layer 4 => depends on: common, config, system
│   ├── rendering/  # Layer 5 => depends on: common, config, system, generation
│   ├── extern/
│   │   ├── headers/   # Contains extern c++ headers (hpp)
│   │   └── libraries/ # Contains extern libs
│   └── catnap.nim  # Entry point
├── scripts/     # Test Scripts etc.
├── config.nims  # nim install, nim debug, ...
└── CHANGELOG.md # Changelog for current development version (versionctl print)

```

## Module layer rules

The `src/` tree is divided into strict dependency layers. A module **may only import from its own layer or lower**; importing upward is forbidden.

| Layer | Package | May import |
|-------|---------|------------|
| 1 | `common/` | stdlib only |
| 2 | `config/` | `common` |
| 3 | `system/` | `common`, `config` |
| 4 | `generation/` | `common`, `config`, `system` |
| 5 | `rendering/` | `common`, `config`, `system`, `generation` |

# How to add a new distro

1. Add the distro's logo in the default `distros.toml` in the `config/` folder. Please arrange the distro in alphabetical order.
2. In `src/catnaplib/global/definitions.nim`, go to the `PKGMANAGERS` section.
3. According to the name of the distro in `config/distros.toml`, put a new line like this:
```nim
"name of distro": "name of package manager",
```
4. If your distro's package manager is already in the `PKGCOUNTCOMMANDS` section, skip the next step.
5. Put your distro's package manager in the `PKGCOUNTCOMMANDS` section like this:
```nim
"name of package manager": "command to get number of packages",
```
6. Submit a pull request to the Catnap repo.
