# wings

A command-line application that performs actions for Flutter application development.

You can verify version numbers, bump version numbers, and more.

The wings application is written completely in Dart and does not use any Ruby code.
There is no need to install Fastlane or write Ruby scripts to perform these types
of actions.

# Install

```
pub global activate wings
```

# Usage

```
wings <command> [arguments]

where command is:
    - playbook
    - command
```

```
wings playbook <playbook_name>
```

```
wings command <command_name>

where command_name is:
    - debug
    - pubspec
    - semver
    - shell
    - version
```

## Command: playbook

## Command: command

### Action: version

```
$ wings command version verify pubspecPath ./pubspec.yaml
Command [version] completed.
{version: 2.2.0+7, valid: true, androidValid: true, androidBuild: 7, build: 7, major: 2, minor: 2, patch: 0, preRelease: [], pubspecPath: ./pubspec.yaml, _name: version}
```

### Action: bump

```
$ wings command version bump type minor pubspecPath ./pubspec.yaml
Command [version] completed.
{version: 2.3.0+7, valid: true, androidValid: true, androidBuild: 7, build: 7, major: 2, minor: 3, patch: 0, preRelease: [], pubspecPath: ./pubspec.yaml, _name: version}
```

# TODO
1. The command version bump should also bump the iOS, Android version numbers.
1. Document how to change out all of the commands.
1. Maybe `wings command` should be `wings task`, to make it more clear, instead of 
having a command called command.
1. Create an agvtool command.
