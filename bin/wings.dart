import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:wings/wings.dart';

/*
  Examples:
    wings <action> <action name> <key> <value>, <key> <value>, ...

    wings command version action: verify pubspecPath: ../pubspec.yaml
    wings command version action: latest pubspecPath: ../pubspec.yaml
    wings command version action: bump type: major pubspecPath: ../pubspec.yaml
    wings command version action: bump type: minor pubspecPath: ../pubspec.yaml
    wings command version action: bump type: patch pubspecPath: ../pubspec.yaml
    wings command version action: bump type: build pubspecPath: ../pubspec.yaml
    wings command version action: set version: 1.2.3 pubspecPath: ../pubspec.yaml
*/

class WingsApp {
  /// Runs the app.
  /// Returns the exit code.
  Future<int> run(List<String> arguments) async {
    final result = await processArguments(arguments);
    return result ? 0 : 1;
  }

  Future<bool> processArguments(List<String> arguments) async {
    final runner = createArgumentRunner();
    try {
      await runner.run(arguments);
      return Future.value(true);
    } on Exception catch (e) {
      WingsLog.error("command runner exception: $e");
    }

    return Future.value(false);
  }

  CommandRunner createArgumentRunner() {
    final runner = CommandRunner('wings', 'A Flutter helper tool.');

    // Add top level commands
    runner.addCommand(CommandCommand());
    runner.addCommand(PlayBookCommand());

    // Add global flags
    runner.argParser.addFlag('verbose', abbr: 'v', help: 'increase logging');

    return runner;
  }
}

class CommandCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = "command";

  @override
  final description = "command: Runs a command.";

  late List<WingsCommand> _commands;

  CommandCommand() {
    _commands = gatherCommands();
    for (final command in _commands) {
      addSubcommand(CLICommand(
          name: command.name,
          description: command.shortDescription,
          wingsCommand: command));
    }
  }

  /// Process all of the entered arguments, and run the command.
  @override
  void run() async {
    if (argResults == null) return;

    if (argResults!.arguments.isEmpty) {
      WingsLog.error("CommandCommand.run: missing command name");
      return;
    }
    final args = argResults!.rest.toList();
    final commandName = args.removeAt(0);
    if (!isValidCommandName(commandName)) {
      WingsLog.error("CommandCommand.run: invalid command name: $commandName");
      return;
    }

    final params = argsToParams(args);
    final command = commandForName(commandName);
    if (command == null) {
      return;
    }
    final result =
        await command.process(context: PlayContext(), params: params);
    WingsLog.message('Command [$commandName] completed.\n$result');
  }

  List<WingsCommand> gatherCommands() {
    return [
      VersionCommand(),
      PubspecCommand(),
      SemverCommand(),
      ShellCommand(),
    ];
  }

  bool isValidCommandName(String name) {
    return _commands.any((command) => command.name == name);
  }

  WingsCommand? commandForName(String name) {
    for (final command in _commands) {
      if (command.name == name) return command;
    }
    return null;
  }
}

// Designed for generic CLI commands.
class CLICommand extends Command {
  final String _name;
  final String _description;
  final WingsCommand wingsCommand;

  @override
  String get name => _name;
  @override
  String get description => _description;

  CLICommand(
      {required String name,
      required String description,
      required this.wingsCommand})
      : _name = name,
        _description = description;

  @override
  void run() async {
    Map<String, String> params = {};
    if (argResults != null) {
      params = argsToParams(argResults!.rest);
    }
    final result =
        await wingsCommand.process(context: PlayContext(), params: params);
    print(result);
  }
}

class PlayBookCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = "playbook";

  @override
  final description = "playbook: Runs a Playbook.";

  PlayBookCommand() {
    // we can add command specific arguments here.
    // [argParser] is automatically created by the parent class.
    argParser.addFlag('all', abbr: 'a');
  }

  // [run] may also return a Future.
  @override
  void run() {
    // [argResults] is set before [run()] is called and contains the flags/options
    // passed to this command.
    print(argResults?['all']);
  }
}

extension CommandParams on Command {
  Map<String, String> argsToParams(List<String> args) {
    bool isKey = true;
    String? key, value;
    final params = <String, String>{};
    for (var arg in args) {
      if (isKey) {
        isKey = false;
        key = arg.replaceAll(':', '');
      } else {
        isKey = true;
        value = arg;
        params[key!] = value;
      }
    }
    return params;
  }
}

/// The main CLI app.
void main(List<String> arguments) async {
  exitCode = await WingsApp().run(arguments);
}
