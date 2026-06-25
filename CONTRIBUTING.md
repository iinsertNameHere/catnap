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
│   ├── config.cat   # Main config (DSL)
│   ├── distros.cat  # Distro art config (DSL)
│   └── themes/      # Example themes
├── docs/  # Contains man docs
├── image/ # Contains all images for README.md
├── src/
│   ├── common/     # Layer 1 => no internal deps, imports stdlib only
│   ├── config/     # Layer 2 => depends on: common
│   │   └── dsl/    # Custom config DSL (Domain-Specific Config Language)
│   ├── system/     # Layer 3 => depends on: common, config
│   ├── generation/ # Layer 4 => depends on: common, config, system
│   ├── rendering/  # Layer 5 => depends on: common, config, system, generation
│   ├── extern/
│   │   └── headers/ # C headers
│   └── catnap.nim  # Entry point
├── scripts/     # Test scripts
└── config.nims  # nim install, nim debug, ...

```

## Module layer rules

The `src/` tree is divided into strict dependency layers. A module **may only import from its own layer or lower**, importing upward is forbidden.

| Layer | Package | May import |
|-------|---------|------------|
| 1 | `common/` | stdlib only |
| 2 | `config/` | `common` |
| 3 | `system/` | `common`, `config` |
| 4 | `generation/` | `common`, `config`, `system` |
| 5 | `rendering/` | `common`, `config`, `system`, `generation` |

# How to add a new distro

1. Add the distro's art block in `config/distros.cat`, inside the `$distros` list. Keep entries in alphabetical order. Use `{%name ["line1" ...] margin=[top left right]}` — multiple names for aliases: `{%mint %linuxmint [...]}`.
2. In `src/common/definitions.nim`, add an entry to `PKGMANAGERS`:
```nim
"distroname": "pkgmanager",
```
3. If the package manager is new, also add it to `PKGCOUNTCOMMANDS` in the same file:
```nim
"pkgmanager": "command to count installed packages",
```
4. Submit a pull request to the Catnap repo.
