/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import '../command_support/wings_commands.dart';
import '../commands/shell_command.dart';

/// Executes the agvtool command line app from Apple.
class AgvtoolCommand extends WingsCommand {
  @override
  String get name => 'wings.agvtool';

  @override
  String get shortDescription =>
      'Executes the agvtool command line app from Apple.';

  @override
  String get docDescription => '''
    Parameters:
      action: <action_name>   The action_name can be one of the following:
        new-marketing-version:
        new-version version:
        what-marketing-version:
        what-version: 
      chdir: <directory>      Change into this directory before running the command.
      version: <number>       The version associated with the action.
  ''';

  @override
  String get docExamples => '''
    wings command wings.agvtool action: new-marketing-version version: 1.2 chdir: "ios"
    wings command wings.agvtool action: new-version version: 1.2.3
    wings command wings.agvtool action: what-marketing-version
    wings command wings.agvtool action: what-version
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

  get _actions => {
        'new-marketing-version': _newMarketingVersionAction,
        'new-version': _newVersionAction,
        'what-marketing-version': _whatMarketingVersionAction,
        'what-version': _whatVersionAction,
      };

  @override
  Future<CommandResult> process({
    required PlayContext context,
    required Map<String, dynamic> params,
  }) async {
    final action = _actions[params['action']];
    if (action == null) return fail({'message': 'unknown action'});

    final chdir = params['chdir'];
    if (chdir != null && chdir is! String) {
      return Future.value(fail({'message': 'invalid chdir'}));
    }

    return await action(context: context, params: params);
  }

  Future<CommandResult> _newMarketingVersionAction(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    return fail({'message': 'empty version'});
  }

  Future<CommandResult> _newVersionAction(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    return fail({'message': 'empty version'});
  }

  Future<CommandResult> _whatMarketingVersionAction(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    final shell = ShellCommand();
    final chdir = params['chdir'];

    final result = await shell.process(context: context, params: {
      'cmd': 'xcrun agvtool what-marketing-version',
      'chdir': chdir
    });

    if (result.didFail) return fail(result.fail!);
    final stdout = result.result!['stdout'];
    if (stdout == null) return fail({'message': 'no response'});
    if (stdout
        .toString()
        .startsWith('There are no Xcode project files in this directory')) {
      return fail({'message': stdout});
    }
    final matches = parseWhatMarketingVersionResponse(stdout);
    if (matches == null) return fail({'message': 'invalid response'});

    final name = matches[0];
    final version = matches[1];

    return pass({'name': name, 'version': version});
  }

  Future<CommandResult> _whatVersionAction(
      {required PlayContext context,
      required Map<String, dynamic> params}) async {
    final shell = ShellCommand();
    final chdir = params['chdir'];

    final result = await shell.process(
        context: context,
        params: {'cmd': 'xcrun agvtool what-version', 'chdir': chdir});

    if (result.didFail) return fail(result.fail!);
    final stdout = result.result!['stdout'];
    if (stdout == null) return fail({'message': 'no response'});
    if (stdout
        .toString()
        .startsWith('There are no Xcode project files in this directory')) {
      return fail({'message': stdout});
    }
    final matches = parseWhatVersionResponse(stdout);
    if (matches == null) return fail({'message': 'invalid response'});

    final name = matches[0];
    final version = matches[1];

    return pass({'name': name, 'version': version});
  }

  //Found CFBundleShortVersionString of "$(MARKETING_VERSION)" in "Runner.xcodeproj/../Runner/Info.plist"
  // terse1: $(MARKETING_VERSION)
  String? parseWhatMarketingVersionResponse(String input) {
    if (input.startsWith(
        'Found CFBundleShortVersionString of "\$(MARKETING_VERSION)" in')) {
      return ('MARKETING_VERSION');
    }
    if (input == '\$(MARKETING_VERSION)') {
      return ('MARKETING_VERSION');
    }
    return null;
  }

  /// Finds the app name and version from the response from agvtool.
  /// Returns an array with first element [name] and second element [version].
  List<String>? parseWhatVersionResponse(String input) {
    final regex =
        r"^Current version of project (?<name>.+) is: \n\s*(?<version>.+)\s*$";
    final pattern = RegExp(regex);
    final matches = pattern.allMatches(input);
    for (final match in matches) {
      print(match);
      final name = match.namedGroup('name');
      final version = match.namedGroup('version');
      if (name != null &&
          name.isNotEmpty &&
          version != null &&
          version.isNotEmpty) {
        return [name, version];
      }
    }
    return null;
  }
}
