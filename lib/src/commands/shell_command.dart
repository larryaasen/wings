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
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => '''
    wings command shell cmd: "dart --version"
    wings command shell cmd: "ls"
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

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    final cmd = params['cmd'];
    if (cmd == null || cmd is! String) {
      return Future.value(fail({'message': 'missing cmd'}));
    }
    var args = cmd.split(' ');
    if (args.isEmpty) {
      return Future.value(fail({'message': 'missing arguments'}));
    }
    final executable = args.first;
    args.removeAt(0);

    final process = await Process.run(executable, args, runInShell: true);
    return pass({
      'exitCode': '${process.exitCode}',
      'stdout': process.stdout,
      'stderr': process.stderr,
    });
  }
}
