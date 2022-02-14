/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:path/path.dart' as pathlib;
import 'package:pubspec/pubspec.dart';

import 'semver_command.dart';

class ProcessEngine {
  final _playbooks = <Playbook>[];

  void run({Playbook? inputPlaybook}) {
    if (inputPlaybook != null) {
      _playbooks.add(inputPlaybook);
    }

    setup();
    processInputs();
    processPlaybooks();
  }

  void setup() {}

  void processInputs() {}

  void processPlaybooks() {
    for (var playbook in _playbooks) {
      playbook.process();
    }
  }
}

class Playbook {
  final List<Play> plays;

  Playbook({this.plays = const <Play>[]});

  void process() {
    for (var play in plays) {
      play.process(playbook: this);
    }
  }
}

class Play {
  final String name;
  final List<Task> tasks;

  Play({this.name = "", this.tasks = const <Task>[]});

  void process({required Playbook playbook}) {
    print("PLAY [$name]");
    final context = PlayContext();
    setupVars();
    processTasks(context: context);
  }

  void setupVars() {}
  void processTasks({required PlayContext context}) {
    for (var task in tasks) {
      task.process(context: context, play: this);
    }
  }
}

class Task {
  final String name;
  final WingsCommand? command;
  final Map<String, dynamic> params;

  Task({this.name = '', this.command, this.params = const {}});

  void process({required PlayContext context, required Play play}) async {
    print("TASK [$name]");
    processFunctions();
    processCommand(context: context);
  }

  void processFunctions() {}
  void processCommand({required PlayContext context}) async {
    if (command != null) {
      final result = await command?.process(context: context, params: params);
      print(result);
    }
  }
}

/// NO GLOBALS! Use the context!

class PlayContext {
  final bool checkMode;

  PlayContext({this.checkMode = false});
}

abstract class PlayFunction {}

class SomeFunction extends PlayFunction {}

enum PlayParameterType { string, bool }

class PlayParameterDef<T> {
  final T type;
  final bool required;

  PlayParameterDef({required this.type, this.required = true});
}

/// The result returned from the processing of a command.
class CommandResult {
  final Map<String, dynamic>? fail;
  final Map<String, dynamic>? result;

  CommandResult({this.fail, this.result}) {
    assert(fail != null || result != null);
  }

  factory CommandResult.fail(Map<String, dynamic> fail) =>
      CommandResult(fail: fail);
  factory CommandResult.result(Map<String, dynamic> result) =>
      CommandResult(result: result);
  bool get didFail => fail != null;
  bool get hasResult => result != null;

  @override
  String toString() {
    return didFail ? 'fail: ${fail.toString()}' : result.toString();
  }
}

abstract class WingsCommand {
  String get name;
  Map get parameterDefinitions;
  Map get metadata;
  String get docDescription;
  String get docExamples;
  String get docReturn;
  bool get supportsCheckMode => false;

  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  });

  CommandResult fail(Map<String, dynamic> params) {
    if (!params.containsKey('_name')) {
      final map = Map<String, dynamic>.from(params);
      map['_name'] = name;
      return CommandResult(fail: map);
    }
    return CommandResult(fail: params);
  }
}

class VersionCommand extends WingsCommand {
  @override
  String get name => 'version';

  @override
  Map get metadata {
    return {"version": "1.1"};
  }

  @override
  Map get parameterDefinitions => {"command": PlayParameterDef(type: String)};

  @override
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => throw UnimplementedError();

  @override
  // TODO: implement docReturn
  String get docReturn => throw UnimplementedError();

  @override
  bool get supportsCheckMode => true;

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    if (params['command'] == "verify") {
      if (context.checkMode) {
        print("check mode: ");
        print("verify: completed");
      }
      final path = params['pubspecPath'];
      final pubspecCommand = PubspecCommand();
      final pubspecResult = await pubspecCommand
          .process(context: context, params: {'path': path});
      if (pubspecResult.didFail) {
        return fail(pubspecResult.fail!);
      }
      final pubspec = pubspecResult.result!;

      final version = pubspec['version'];
      if (version == null) {
        return fail({'message': 'empty version'});
      }

      final semverCommand = SemverCommand();
      final semverResult = await semverCommand.process(
          context: context, params: {'command': 'parse', 'version': version});
      if (semverResult.didFail) {
        return fail(semverResult.fail!);
      }

      int? androidBuild;
      var isAndroidValid = false;
      if (semverResult.result!['build'] != null &&
          (semverResult.result!['build'] as String).isNotEmpty) {
        if (int.tryParse(semverResult.result!['build']) != null) {
          androidBuild = int.parse(semverResult.result!['build']);
          isAndroidValid = true;
        }
      }
      var result = {
        'version': version,
        'valid': true,
        'androidValid': isAndroidValid,
        if (androidBuild != null) 'androidBuild': androidBuild,
        'build': semverResult.result!['build'],
        'major': semverResult.result!['major'],
        'minor': semverResult.result!['minor'],
        'patch': semverResult.result!['patch'],
        'preRelease': semverResult.result!['preRelease'],
        'pubspecPath': pathlib.absolute(path),
      };
      return Future.value(CommandResult.result(result));
    }
    return Future.value(fail({'message': 'unknown command'}));
  }
}

/// Loads a pubspec file.
class PubspecCommand extends WingsCommand {
  @override
  String get name => 'pubspec';

  @override
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => throw UnimplementedError();

  @override
  // TODO: implement docReturn
  String get docReturn => throw UnimplementedError();

  @override
  // TODO: implement metadata
  Map get metadata => throw UnimplementedError();

  @override
  // TODO: implement parameterDefinitions
  Map get parameterDefinitions => throw UnimplementedError();

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    if (params['path'] == null) {
      return Future.value(fail({'message': 'missing path'}));
    }
    // specify the path to the pubspec.yaml file.
    var path = params['path'];
    path = pathlib.absolute(path);

    try {
      // load pubSpec
      var pubSpec = await PubSpec.loadFile(path);
      return CommandResult.result(pubSpec
          .toJson()
          .map((key, value) => MapEntry(key, value.toString())));
    } on Exception catch (e) {
      return Future.value(fail({'message': 'exception: $e'}));
    }
  }
}
