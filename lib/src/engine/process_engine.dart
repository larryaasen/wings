/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import '../command_support/wings_commands.dart';

class YamlLoader {
  /// Loads a playbook file and returns a list of the plays.
  /// Returns a [List] containing the plays in the file.
  /// Throws when the file does not exist, or the YAML does not load.
  Future<List> loadPlaybook(String playbookName) async {
    // Read YAML file
    final file = File(playbookName);
    if (!file.existsSync()) {
      throw Exception('Playbook does not exist: $playbookName');
    }
    final contents = await file.readAsString();
    if (contents.isNotEmpty) {
      try {
        // Parse YAML file
        final doc = yaml.loadYaml(contents);

        // Convert to a JSON string
        final rawJson = json.encode(doc);

        // Convert JSON string to a List
        final plays = jsonDecode(rawJson);

        if (plays is List) return plays;
        throw Exception('invalid yaml file $playbookName');
      } on Exception catch (e) {
        throw Exception('yaml exception $e for file $playbookName');
      }
    }

    return [];
  }
}

class PlaybookLoader {
  final WingsCommands _commands = WingsCommands();

  /// Create playbook from a List
  Future<Playbooks> load(List plays) async {
    List<Play> allPlays = [];
    for (final play in plays) {
      String? playName;
      if (play['name'] is String) {
        playName = play['name'];
      }
      if (play['tasks'] is List) {
        List<Task> allTasks = [];
        List tasks = play['tasks'];
        for (final task in tasks) {
          if (task is Map) {
            String? taskName;
            WingsCommand? taskCommand;
            Map<String, dynamic>? taskCommandParams;

            for (final key in task.keys) {
              if (key == 'name') {
                taskName = task[key];
              } else if (key == 'dada') {
              } else if (isTaskCommand(key)) {
                final commandName = key;
                taskCommand = _commands.commandForName(commandName);
                if (task[key] is Map) {
                  final Map params = task[key];
                  taskCommandParams = params
                      .map((key, value) => MapEntry(key.toString(), value));
                }
              }
            }
            if (taskCommand != null) {
              allTasks.add(Task(
                  name: taskName ?? '',
                  command: taskCommand,
                  params: taskCommandParams ?? {}));
            }
          }
        }
        allPlays.add(Play(name: playName ?? '', tasks: allTasks));
      }
    }
    final playbook = Playbook(plays: allPlays);
    return Playbooks(all: [playbook]);
  }

  bool isTaskCommand(String key) {
    return _commands.isValidCommandName(key);
  }
}

class WingsEnvironment {
  final WingsOptions options;
  final Playbooks playbooks;
  final List<String> errors;

  WingsEnvironment({
    required this.options,
    required this.playbooks,
    required this.errors,
  });
}

class WingsOptions {
  final bool verbose;

  WingsOptions({this.verbose = false});
}

class WingsLoader {
  /// Load all playbooks and create the environment.
  Future<WingsEnvironment> load({
    required List<String> playbookNames,
    required WingsOptions options,
    required YamlLoader yamlLoader,
    required PlaybookLoader playbookLoader,
  }) async {
    var validNames = <String>[];
    List<String> errors = [];
    for (final playbookName in playbookNames) {
      if (isValidPlaybookName(playbookName)) {
        validNames.add(playbookName);
      } else {
        errors.add('invalid playbook name: $playbookName');
        WingsLog.error(
            "WingsLoader.load: invalid playbook name: $playbookName");
      }
    }

    List<Playbook> allPlaybooks = [];
    for (final playbookName in validNames) {
      try {
        final plays = await yamlLoader.loadPlaybook(playbookName);
        final playbooks = await playbookLoader.load(plays);
        allPlaybooks.addAll(playbooks.all);
      } on Exception catch (e) {
        errors.add(e.toString());
      }
    }

    return WingsEnvironment(
      options: options,
      playbooks: Playbooks(all: allPlaybooks),
      errors: errors,
    );
  }

  bool isValidPlaybookName(String playbookName) {
    return playbookName.isNotEmpty;
  }
}

class ProcessEngine {
  final _playbooks = <Playbook>[];

  void run({required WingsEnvironment environment}) async {
    _playbooks.addAll(environment.playbooks.all);

    setup();
    processInputs();
    await processPlaybooks();
  }

  void setup() {}

  void processInputs() {}

  Future<void> processPlaybooks() async {
    for (var playbook in _playbooks) {
      await playbook.process();
    }
  }
}

class Playbooks {
  final List<Playbook> all;

  Playbooks({required this.all});
}

class Playbook {
  final List<Play> plays;

  Playbook({this.plays = const <Play>[]});

  Future<void> process() async {
    for (var play in plays) {
      await play.process(playbook: this);
    }
  }
}

class Play {
  final String name;
  final List<Task> tasks;

  Play({this.name = '', this.tasks = const <Task>[]});

  Future<void> process({required Playbook playbook}) async {
    print('\nPLAY [$name]');
    final context = PlayContext();
    setupVars();
    await processTasks(context: context);
  }

  void setupVars() {}
  Future<bool> processTasks({required PlayContext context}) async {
    for (var task in tasks) {
      await task.process(context: context, play: this);
    }
    return true;
  }
}

class Task {
  final String name;
  final WingsCommand? command;
  final Map<String, dynamic> params;

  Task({this.name = '', this.command, this.params = const {}});

  String get taskName {
    if (name.isNotEmpty) return name;
    return command != null ? command!.name : '';
  }

  Future<bool> process(
      {required PlayContext context, required Play play}) async {
    print('\nTASK [$taskName]');
    processFunctions();
    await processCommand(context: context);
    return true;
  }

  void processFunctions() {}
  Future<bool> processCommand({required PlayContext context}) async {
    if (command != null) {
      final result = await command?.process(context: context, params: params);
      print(result);
      return true;
    }
    return false;
  }
}

/// NO GLOBALS! Use the context!
