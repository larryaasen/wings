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
    // if (arguments.isEmpty) {
    //   return 1;
    // }

    final result = await processArguments(arguments);

    return 0;

    final playBook = testPlaybook();

    final engine = ProcessEngine();
    engine.run(inputPlaybook: playBook);
  }

  Future<bool> processArguments(List<String> arguments) async {
    final runner = createArgumentRunner();
    // final results = runner.parse(arguments);
    // print('usage:\n${runner.usage}');
    try {
      await runner.run(arguments);
      return Future.value(true);
    } on Exception catch (e) {
      print("command runner exception: $e");
    }

    return Future.value(false);
  }

  CommandRunner createArgumentRunner() {
    final runner = CommandRunner('wings', 'A Flutter helper tool.');

    // Add commands
    // runner.addCommand(
    //     CLICommand(name: 'command', description: 'Runs a command.'));
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
  final description = "Runs a command.";

  CommandCommand() {
    // we can add command specific arguments here.
    // [argParser] is automatically created by the parent class.
    argParser.addFlag('all', abbr: 'a');
  }

  // [run] may also return a Future.
  @override
  void run() async {
    if (argResults == null) {
      return;
    }
    if (argResults!.arguments.isEmpty) {
      print("CommandCommand.run: missing command name");
      return;
    }
    final args = argResults!.rest.toList();
    final commandName = args.removeAt(0);
    if (!isValidCommandName(commandName)) {
      print("CommandCommand.run: invalid command name: $commandName");
      return;
    }

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
    final command = commandForName(commandName);
    if (command == null) {
      return;
    }
    final result =
        await command.process(context: PlayContext(), params: params);
    print('Command [$commandName] completed.\n$result');
  }

  bool isValidCommandName(String name) {
    return name == 'version' || name == 'pubspec' || name == 'semver';
  }

  WingsCommand? commandForName(String name) {
    final commands = {
      'version': VersionCommand(),
      'pubspec': PubspecCommand(),
      'semver': SemverCommand()
    };
    return commands[name];
  }
}

// Not used. Designed for generic CLI commands.
class CLICommand extends Command {
  final String _name;
  final String _description;
  final Function _run;

  @override
  String get name => _name;
  @override
  String get description => _description;

  CLICommand(
      {required String name,
      required String description,
      required Function run})
      : _name = name,
        _description = description,
        _run = run;

  @override
  void run() => _run();
}

class PlayBookCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = "playbook";

  @override
  final description = "Runs a Playbook.";

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

void main(List<String> arguments) async {
  exitCode = await WingsApp().run(arguments);
}

Playbook testPlaybook() {
  final version = VersionCommand();
  final task = Task(
      name: 'Verify the version',
      command: version,
      params: {'action': 'verify', 'pubspecPath': './pubspec.yaml'});
  final play = Play(name: 'Versioning', tasks: [task]);
  final playBook = Playbook(plays: [play]);
  return playBook;
}
