/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:intl/intl.dart';
import 'package:path/path.dart' as pathlib;

import 'pubspec_command.dart';
import 'semver_command.dart';

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

  Play({this.name = '', this.tasks = const <Task>[]});

  void process({required Playbook playbook}) {
    print('PLAY [$name]');
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
    print('TASK [$name]');
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
  /// The name of the command. It should be one word and lower case. Use by the
  /// CLI and Playbooks.
  String get name;

  Map get parameterDefinitions;
  Map get metadata;
  String get shortDescription;
  String get docDescription;
  String get docExamples;
  String get docReturn;
  bool get supportsCheckMode => false;

  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  });

  /// Generate a fail [CommandResult] to be returned.
  Future<CommandResult> fail(Map<String, dynamic> params) {
    if (!params.containsKey('_name')) {
      final map = Map<String, dynamic>.from(params);
      map['_name'] = name;
      return Future.value(CommandResult(fail: map));
    }
    return Future.value(CommandResult(fail: params));
  }

  /// Generate a result [CommandResult] to be returned.
  Future<CommandResult> pass(Map<String, dynamic> params) {
    if (!params.containsKey('_name')) {
      final map = Map<String, dynamic>.from(params);
      map['_name'] = name;
      return Future.value(CommandResult(result: map));
    }
    return Future.value(CommandResult(result: params));
  }
}

/// The version command verifys the version number in a pubspec. It can also
/// update the version number in the pubspec.
class VersionCommand extends WingsCommand {
  @override
  String get name => 'version';

  @override
  Map get metadata {
    return {'version': '1.1'};
  }

  @override
  Map get parameterDefinitions => {'action': PlayParameterDef(type: String)};

  @override
  String get shortDescription => 'Verifies or updates a version number.';

  @override
  String get docDescription => '''
    command: version
    params:
      action:
        verify - verify the version in the pubspec.
        latest - Use the latest version number in the platforms file, and update
        to that version.
        bump - Update the version number by bumping the major, minor, patch, or
        build.
          major
          minor
          patch
          build

    wings command version action: verify pubspecPath: ../pubspec.yaml
    wings command version action: latest pubspecPath: ../pubspec.yaml
    wings command version action: bump type: major pubspecPath: ../pubspec.yaml
    wings command version action: bump type: minor pubspecPath: ../pubspec.yaml
    wings command version action: bump type: patch pubspecPath: ../pubspec.yaml
    wings command version action: bump type: build pubspecPath: ../pubspec.yaml
    wings command version action: set version: 1.2.3 pubspecPath: ../pubspec.yaml
    ''';

  @override
  // TODO: implement docExamples
  String get docExamples => throw UnimplementedError();

  @override
  // TODO: implement docReturn
  String get docReturn => throw UnimplementedError();

  @override
  bool get supportsCheckMode => true;

  get _actions => {'verify': _verifyAction, 'bump': _bumpAction};

  static final _typesToActions = {
    'major': 'incrementMajor',
    'minor': 'incrementMinor',
    'patch': 'incrementPatch',
    'build': 'incrementBuild',
  };

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    final action = _actions[params['action']];
    if (action == null) return fail({'message': 'unknown action'});
    return action(context: context, params: params);
  }

  Future<CommandResult> _bumpAction(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    if (context.checkMode) {
      // TODO: finish check mode
    }

    // Read the pubspec
    final path = params['pubspecPath'];
    final pubspecCommand = PubspecCommand();
    final pubspecResult = await pubspecCommand
        .process(context: context, params: {'action': 'read', 'path': path});
    if (pubspecResult.didFail) {
      return fail(pubspecResult.fail!);
    }
    final pubspec = pubspecResult.result!;

    final version = pubspec['version'];
    if (version == null) {
      return fail({'message': 'pubspec has empty version'});
    }

    final semverAction = _typesToActions[params['type']];
    if (semverAction == null) {
      return fail({'message': 'type is unknown'});
    }

    final semverCommand = SemverCommand();
    final semverResult = await semverCommand.process(
        context: context, params: {'action': semverAction, 'version': version});
    if (semverResult.hasResult) {
      final newVersion = semverResult.result!['version'];
      // Bump the major version
      final pubspecResult = await pubspecCommand.process(
          context: context,
          params: {'action': 'update', 'path': path, 'version': newVersion});
      if (pubspecResult.didFail) {
        return fail(pubspecResult.fail!);
      }
      return pass(_result(semverResult.result!, path));
    }
    return fail(semverResult.fail!);
  }

  Future<CommandResult> _verifyAction(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    if (context.checkMode) {
      print('check mode: ');
      print('verify: completed');
    }
    final path = params['pubspecPath'];
    final pubspecCommand = PubspecCommand();
    final pubspecResult = await pubspecCommand
        .process(context: context, params: {'action': 'read', 'path': path});
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
        context: context, params: {'action': 'parse', 'version': version});
    if (semverResult.didFail) {
      return fail(semverResult.fail!);
    }
    return pass(_result(semverResult.result!, path));
  }

  Map<String, dynamic> _result(Map<String, dynamic> semverResult, String path) {
    int? androidBuild;
    var isAndroidValid = false;
    if (semverResult['build'] != null &&
        (semverResult['build'] as String).isNotEmpty) {
      if (int.tryParse(semverResult['build']) != null) {
        androidBuild = int.parse(semverResult['build']);
        isAndroidValid = true;
      }
    }
    var result = {
      'version': semverResult['version'],
      'valid': true,
      'androidValid': isAndroidValid,
      if (androidBuild != null) 'androidBuild': androidBuild,
      'build': semverResult['build'],
      'major': semverResult['major'],
      'minor': semverResult['minor'],
      'patch': semverResult['patch'],
      'preRelease': semverResult['preRelease'],
      'pubspecPath': pathlib.absolute(path),
    };
    return result;
  }
}

class WingsLog {
  static void message(String message, {String group = ''}) {
    _output(message, group);
  }

  static void error(String message, {String group = ''}) {
    _output(message, group);
  }

  static final formatterLogMilli = DateFormat('y/M/d H:mm:ss.SSS');
  static final formatSystemLog = formatterLogMilli.format(DateTime.now());

  static void _output(String message, String group) {
    final groupMsg = group.isEmpty ? '' : " [$group]";
    final timeMsg = formatSystemLog;
    print("$timeMsg$groupMsg $message");
  }
}
