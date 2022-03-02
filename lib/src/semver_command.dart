/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:version/version.dart';

import 'process_engine.dart';
import 'wings_commands.dart';

class SemverCommand extends WingsCommand {
  @override
  String get name => 'wings.semver';

  @override
  String get shortDescription => 'Verifies or updates semantic versions.';

  @override
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => '''
    wings command semver action: parse: version: 1.2.3
    wings command semver action: incrementMajor version: 1.2.3
    wings command semver action: incrementMinor version: 1.2.3
    wings command semver action: incrementPatch version: 1.2.3
    wings command semver action: incrementBuild version: 1.2.3

    tasks:
      - name: verify version
        command: server
          action: parse
          version: 1.2.3
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
  Future<CommandResult> process(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    final versionString = params['version'];
    try {
      Version version = Version.parse(versionString);
      final action = params['action'];
      if (action == 'parse') {
        return Future.value(resultFromVersion(version));
      } else if (params['action'] == 'incrementMajor') {
        version = Version(
          version.major + 1,
          0,
          0,
          preRelease: const <String>[],
          build: version.build,
        );
        return Future.value(resultFromVersion(version));
      } else if (params['action'] == 'incrementMinor') {
        version = Version(
          version.major,
          version.minor + 1,
          0,
          preRelease: const <String>[],
          build: version.build,
        );
        return Future.value(resultFromVersion(version));
      } else if (params['action'] == 'incrementPatch') {
        version = Version(
          version.major,
          version.minor,
          version.patch + 1,
          preRelease: const <String>[],
          build: version.build,
        );
        return Future.value(resultFromVersion(version));
      } else if (params['action'] == 'incrementBuild') {
        if (int.tryParse(version.build) != null) {
          final build = int.parse(version.build) + 1;
          version = Version(
            version.major,
            version.minor,
            version.patch,
            preRelease: const <String>[],
            build: build.toString(),
          );
        } else {
          return Future.value(fail({'message': 'cannot increment build'}));
        }
        return Future.value(resultFromVersion(version));
      } else {
        return Future.value(fail({'message': 'unknown action: $action'}));
      }
    } catch (e) {
      return Future.value(fail({'message': 'exception: $e'}));
    }
  }

  CommandResult resultFromVersion(Version version) {
    final result = {
      'build': version.build,
      'major': version.major,
      'minor': version.minor,
      'patch': version.patch,
      'preRelease': version.preRelease,
      'version': version.toString(),
    };
    return CommandResult.result(result);
  }
}
