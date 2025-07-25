import strutils
import os
import strformat
import re

const versionFile = "src/catnaplib/global/version.nim"
const changelogFile = "CHANGELOG.md"

proc usage() =
  echo "Usage: versionctl {ACTION}"
  echo ""
  echo "Version Format:"
  echo "  Format:  {major}.{minor}.{patch}"
  echo "  Example:   2.11.3"
  echo ""
  echo "ACTIONS:"
  echo "  major     Bump major version"
  echo "  minor     Bump minor version"
  echo "  patch     Bump patch version"
  echo "  validate  Validate for release "
  echo "  print     Print the current development version"
  echo ""

proc validateVersion(version: string) =
  if not version.match(re"\d+\.\d+\.\d+"):
    echo "Version must be SemVer (X.Y.Z)!"

proc bumpVersion(part: string): string =
  let content = readFile(versionFile)
  let oldVersion = content.split('"')[1]
  validateVersion(oldVersion)

  let parts = oldVersion.split('.')
  if parts.len != 3:
    echo "Version must be in MAJOR.MINOR.PATCH format"
    return ""
  
  var major = parts[0].parseInt()
  var minor = parts[1].parseInt()
  var patch = parts[2].parseInt()

  case part.toLowerAscii():
    of "major": major += 1; minor = 0; patch = 0
    of "minor": minor += 1; patch = 0
    of "patch": patch += 1
    else: 
      echo "Invalid part. Use: major|minor|patch"
      return ""

  let newVersion = &"{major}.{minor}.{patch}"
  writeFile(versionFile, content.replace(oldVersion, newVersion))
  echo &"Bumped from v{oldVersion} to v{newVersion}"
  return newVersion

proc checkChangelogUpdated(version: string) =
  let changelog = readFile(changelogFile)
  if not changelog.contains(&"## v{version}"):
    echo fmt"WARNING: {changelogFile} dose not contain an entry for v{version}!"

proc getVersion() =
  let content = readFile(versionFile)
  let version = content.split('"')[1]
  echo version

proc validate() =
  let content = readFile(versionFile)
  let version = content.split('"')[1]
  validateVersion(version)
  checkChangelogUpdated(version)

when isMainModule:
  if paramCount() != 1:
    usage()
    quit(1)

  let part = paramStr(1)
  
  if part == "validate":
    validate()
    quit()
  elif part == "print":
    getVersion()
    quit()
  else:
    let newVersion = bumpVersion(part)
    if newVersion == "": quit(1)
    checkChangelogUpdated(newVersion)