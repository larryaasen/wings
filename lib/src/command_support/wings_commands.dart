import 'package:intl/intl.dart';

import 'wings_command_list.dart';

abstract class PlayFunction {}

class SomeFunction extends PlayFunction {}

enum PlayParameterType { string, bool }

class PlayParameterDef<T> {
  final T type;
  final bool required;

  PlayParameterDef({required this.type, this.required = true});
}

class PlayContext {
  final bool checkMode;

  PlayContext({this.checkMode = false});
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

class WingsCommands {
  List<WingsCommand> get all => _commands;

  late List<WingsCommand> _commands;
  WingsCommands() {
    _commands = _gatherCommands();
  }

  List<WingsCommand> _gatherCommands() => WingsCommandList().all;

  bool isValidCommandName(String name) {
    return commandForName(name) != null;
  }

  WingsCommand? commandForName(String name) {
    // if (name.startsWith('wings.')) {
    //   name = name.substring('wings.'.length);
    // }
    for (final command in _commands) {
      if (command.name == name) return command;
    }
    return null;
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
