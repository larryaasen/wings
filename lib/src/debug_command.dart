/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'dart:io';

import 'process_engine.dart';
import 'wings_commands.dart';

/// Logs messages during execution.
class ShellCommand extends WingsCommand {
  @override
  String get name => 'wings.debug';

  @override
  String get shortDescription => 'Logs messages during execution.';

  @override
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => '''
    wings command debug msg: "Starting a task."
    wings command debug msg: hello
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
    final msg = params['msg'];
    if (msg == null || msg is! String) {
      return Future.value(fail({'message': 'missing msg'}));
    }
    WingsLog.message(msg);
    return pass(params);
  }
}
