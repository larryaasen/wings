/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'dart:io';

import 'package:path/path.dart' as pathlib;
import 'package:pubspec/pubspec.dart';

import 'semver_command.dart';
import '../command_support/wings_commands.dart';

/// Read or write a pubspec file.
class PubspecCommand extends WingsCommand {
  @override
  String get name => 'wings.pubspec';

  @override
  String get shortDescription => 'Reads or updates a pubspec file.';

  @override
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => '''
    wings command pubspec action: read path: ./pubspec.yaml
    wings command pubspec action: update version: 1.2.3 path: ./ pubspec: {}
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

  get _actions => {'read': _readAction, 'update': _updateAction};

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    final action = _actions[params['action']];
    if (action == null) return fail({'message': 'unknown action'});
    return action(context: context, params: params);
  }

  Future<CommandResult> _readAction(
      {required PlayContext context, required Map<String, dynamic> params}) async {
    if (params['path'] == null) {
      return fail({'message': 'missing path'});
    }
    // specify the path to the pubspec.yaml file.
    var path = params['path'];
    path = pathlib.normalize(pathlib.absolute(path));

    try {
      // load pubSpec
      var pubSpec = await PubSpec.loadFile(path);
      return CommandResult.result(pubSpec.toJson().map((key, value) => MapEntry(key.toString(), value)));
    } on Exception catch (e) {
      return fail({'message': 'exception: $e'});
    }
  }

  /// Update a pubspec file.
  /// Params:
  /// - path:
  /// - version:
  Future<CommandResult> _updateAction(
      {required PlayContext context, required Map<String, dynamic> params}) async {
    var path = params['path'];
    path = pathlib.absolute(path);
    if (!await File(path).exists()) {
      return fail({'message': 'path does not exist: $path'});
    }

    final version = params['version'];
    if (version != null && version is String && version.isNotEmpty) {
      return _updateVersion(context, version, path);
    }
    return fail({'message': 'nothing to update'});
  }

  Future<CommandResult> _updateVersion(PlayContext context, String version, String path) async {
    final semverCommand = SemverCommand();
    final semverResult =
        await semverCommand.process(context: context, params: {'action': 'parse', 'version': version});
    if (semverResult.didFail) {
      return fail(semverResult.fail!);
    }

    final contents = await File(path).readAsString();
    final replacement = _replaceVersion(version, contents);
    if (replacement == null) {
      return fail({'message': 'cannot update version: $version'});
    }

    try {
      final result = await File(path).writeAsString(replacement);
      return pass({'saved': true, 'path': result.path});
    } on Exception catch (e) {
      return fail({'message': 'write exception: $e'});
    }
  }

  String? _replaceVersion(String version, String pubspecContents) {
    final regex = RegExp(r'^version:.*$', multiLine: true);
    var processed = false;
    final updated = pubspecContents.replaceAllMapped(regex, (match) {
      if (processed) return '';
      processed = true;
      return 'version: $version';
    });
    return processed ? updated : null;
  }
}
