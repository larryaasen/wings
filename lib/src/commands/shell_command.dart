/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'dart:io';

// import 'process_engine.dart';
import '../command_support/wings_commands.dart';

/// Executes a shell command.
class ShellCommand extends WingsCommand {
  @override
  String get name => 'wings.shell';

  @override
  String get shortDescription => 'Executes a shell command.';

  @override
  String get docDescription => '''
    Parameters:
      cmd: <shell_command>  The command to run followed by optional arguments.
      chdir: <directory>    Change into this directory before running the command.
  ''';

  @override
  String get docExamples => '''
    wings command shell cmd: "dart --version"
    wings command shell cmd: "ls" chdir: "ios"

    final result = ShellCommand().process({'cmd': 'ls', 'chdir': 'ios'});
  ''';

  @override
  // TODO: implement docReturn
  String get docReturn => throw UnimplementedError();

  @override
  // TODO: implement metadata
  Map get metadata => throw UnimplementedError();

  @override
  // TODO: implement parameterDefinitions
  Map get parameterDefinitions => throw UnimplementedError();

  /// Run the shell command.
  Future<CommandResult> run({
    required PlayContext context,
    required String cmd,
    String? chdir,
  }) async {
    if (cmd.isEmpty) {
      return Future.value(fail({'message': 'cmd is empty'}));
    }

    var args = cmd.split(' ');
    final executable = args.first;
    args.removeAt(0);

    try {
      final process = await Process.run(executable, args,
          runInShell: true, workingDirectory: chdir);
      return pass({
        'exitCode': '${process.exitCode}',
        'stdout': process.stdout,
        'stderr': process.stderr,
      });
    } on Exception catch (e) {
      return fail({'message': e.toString()});
    }
  }

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    return run(
        context: context,
        cmd: makeString(params['cmd']),
        chdir: makeString(params['chdir']));
  }
}

/// Returns the value if it is a string, or empty string.
String makeString(dynamic value) {
  return value is String ? value : '';
}

T make<T>(dynamic value) {
  if (value is T) return value;
  if (T is String) return '' as T;
  return null as T;
}
