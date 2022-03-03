import 'package:path/path.dart' as pathlib;

import '../command_support/wings_commands.dart';
import 'pubspec_command.dart';
import 'semver_command.dart';

/// The version command verifys the version number in a pubspec. It can also
/// update the version number in the pubspec.
class VersionCommand extends WingsCommand {
  @override
  String get name => 'wings.version';

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
    return await action(context: context, params: params);
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
      // TODO: check mode
      print('check mode: TBD');
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
