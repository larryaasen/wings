import 'package:wings/src/process_engine.dart';
import 'package:wings/src/wings_command_list.dart';

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
