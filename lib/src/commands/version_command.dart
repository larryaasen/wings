import 'package:path/path.dart' as pathlib;

import '../command_support/wings_commands.dart';
import 'pubspec_command.dart';
import 'semver_command.dart';
import 'shell_command.dart';

/*
Notes:
There are three types of versioning styles used in Flutter iOS apps.
1) The default way Flutter configures versioning for a new app using FLUTTER_BUILD_NUMBER and FLUTTER_BUILD_NAME.
2) A modified way in which hard coded values are entered into either Info.plist or the project.
3) The Apple way using automatic versioning and agvtool.

This version command uses #1 above, the default Flutter way.
*/

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
        verify - verify the version in the pubspec, and in the platform files. For iOS
        it verifies that FLUTTER_BUILD_NUMBER and FLUTTER_BUILD_NAME are used in the
        Info.plist file.
        latest - Use the latest version number in the platforms file, and update
        to that version across all platforms.
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

    TODO:
    1. Maybe remove the need for pubspecPath, and assume current folder, and an
    optional project path instead.
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

  final _shell = ShellCommand();

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
      {required PlayContext context, required Map<String, dynamic> params}) async {
    // Read the pubspec
    final path = params['pubspecPath'];
    final pubspecCommand = PubspecCommand();
    final pubspecResult =
        await pubspecCommand.process(context: context, params: {'action': 'read', 'path': path});
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
    final semverResult =
        await semverCommand.process(context: context, params: {'action': semverAction, 'version': version});
    if (semverResult.hasResult) {
      final newVersion = semverResult.result!['version'];
      // Bump the major version
      final pubspecResult = await pubspecCommand
          .process(context: context, params: {'action': 'update', 'path': path, 'version': newVersion});
      if (pubspecResult.didFail) {
        return fail(pubspecResult.fail!);
      }
      return pass(_result(semverResult.result!, path));
    }
    return fail(semverResult.fail!);
  }

  Future<CommandResult> _verifyAction(
      {required PlayContext context, required Map<String, dynamic> params}) async {
    final path = params['pubspecPath'];
    final pubspecCommand = PubspecCommand();
    final pubspecResult =
        await pubspecCommand.process(context: context, params: {'action': 'read', 'path': path});
    if (pubspecResult.didFail) {
      return fail(pubspecResult.fail!);
    }
    final pubspec = pubspecResult.result!;

    final version = pubspec['version'];
    if (version == null) {
      return fail({'message': 'empty version'});
    }

    final semverCommand = SemverCommand();
    final semverResult =
        await semverCommand.process(context: context, params: {'action': 'parse', 'version': version});
    if (semverResult.didFail) {
      return fail(semverResult.fail!);
    }

    var result = _result(semverResult.result!, path);

    // If one of the platforms is iOS, check the Info.plist file.
    bool hasIOS = true;
    if (hasIOS) {
      // Since path contains the filename, strip that off.

      final projectPath = pathlib.normalize(pathlib.absolute(pathlib.dirname(path)));
      final verifiedResult = await _verifyIOS(context: context, version: version, projectPath: projectPath);
      result.addAll(verifiedResult);
    }

    // Return consolidated results.
    return pass(result);
  }

  Future<Map<String, dynamic>> _verifyIOS(
      {required PlayContext context, required String version, required String projectPath}) async {
    final result = <String, dynamic>{};

    // Verify the short version from the Info.plist file.
    final file = '$projectPath/ios/Runner/Info.plist';
    final shortVersionValue =
        await _plutilExtract(context: context, keypath: PlistUtil.shortVersion, file: file);
    if (shortVersionValue == null || shortVersionValue.isEmpty) {
      result[PlistUtil.shortVersion] = 'missing';
    } else if (shortVersionValue != '\$(FLUTTER_BUILD_NAME)') {
      result[PlistUtil.shortVersion] = 'should be set to \$(FLUTTER_BUILD_NAME)';
    }

    // Verify the short version from the Info.plist file.
    final versionValue = await _plutilExtract(context: context, keypath: PlistUtil.version, file: file);
    if (versionValue == null || versionValue.isEmpty) {
      result[PlistUtil.version] = 'missing';
    } else if (versionValue != '\$(FLUTTER_BUILD_NUMBER)') {
      result[PlistUtil.version] = 'should be set to \$(FLUTTER_BUILD_NUMBER)';
    }

    result['ios_verified'] = result.keys.isEmpty;
    return result;
  }

  /// property list utility - outputs the type for the value at keypath in the
  /// property list. Only works for string type.
  /// Returns null when plutil fails or the keypath is not found.
  /// TODO: make this into a class.
  Future<String?> _plutilType(
      {required PlayContext context, required String keypath, required String file}) async {
    final cmd = '${PlistUtil.plutil} -type $keypath $file';
    final result = await _shell.run(context: context, cmd: cmd);
    if (result.didFail) return null;
    if (result.hasResult && result.result != null) {
      final value = result.result!['stdout'] as String;
      final type =
          value.isNotEmpty && value[value.length - 1] == '\n' ? value.substring(0, value.length - 1) : value;
      if (type == 'string') return 'string';
    }
    return null;
  }

  /// property list utility - outputs the value at keypath in the property list.
  /// Returns null when plutil fails or the keypath is not found.
  /// TODO: make this into a class.
  Future<String?> _plutilExtract(
      {required PlayContext context, required String keypath, required String file}) async {
    final type = await _plutilType(context: context, keypath: keypath, file: file);
    if (type == null) return null;
    final cmd = '${PlistUtil.plutil} -extract $keypath raw $file';
    final result = await _shell.run(context: context, cmd: cmd);
    if (result.didFail) return null;
    if (result.hasResult && result.result != null) {
      final value = result.result!['stdout'] as String;
      final stdout =
          value.isNotEmpty && value[value.length - 1] == '\n' ? value.substring(0, value.length - 1) : value;
      return stdout;
    }
    return null;
  }

  Map<String, dynamic> _result(Map<String, dynamic> semverResult, String path) {
    int? androidBuild;
    var isAndroidValid = false;
    if (semverResult['build'] != null && (semverResult['build'] as String).isNotEmpty) {
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
      'pubspecPath': pathlib.normalize(pathlib.absolute(path)),
    };
    return result;
  }
}

class PlistUtil {
  static const shortVersion = 'CFBundleShortVersionString';
  static const version = 'CFBundleVersion';
  static const plutil = '/usr/bin/plutil';
}
