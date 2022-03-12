/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:test/test.dart';
import 'package:wings/src/commands/agvtool_command.dart';
import 'package:wings/wings.dart';

import '../bin/wings.dart';
import 'helpers.dart';

void main() {
  group('WingsApp', () {
    test('run', () async {
      expect(WingsApp(), isNotNull);
      // expect(WingsApp().run([]), 1);
    });

    test('processArguments verify', () async {
      final args = [
        'command',
        'version',
        'action:',
        'verify',
        'pubspecPath:',
        'test/pubspecs/test1_pubspec.yaml'
      ];
      final wings = WingsApp();
      expect(WingsApp(), isNotNull);
      final result = await wings.processArguments(args);
      print("done: $result");
    });

    test('processArguments bump', () async {
      final args = [
        'command',
        'version',
        'action:',
        'bump',
        'type:',
        'major',
        'pubspecPath:',
        await copyToTmp('test/pubspecs/test1_pubspec.yaml')
      ];
      final wings = WingsApp();
      expect(WingsApp(), isNotNull);
      final result = await wings.processArguments(args);
      print("done: $result");
    });

    test('AgvtoolCommand Runner', () {
      final agvtool = AgvtoolCommand();
      final output = "Current version of project Runner is: \n    1.15.0";
      final values = agvtool.parseWhatVersionResponse(output);
      expect(values, isNotNull);
      expect(values![0], 'Runner');
      expect(values[1], '1.15.0');
    });

    test('AgvtoolCommand MyProject', () {
      final agvtool = AgvtoolCommand();
      final output = "Current version of project MyProject is: \n    2.2";
      final values = agvtool.parseWhatVersionResponse(output);
      expect(values, isNotNull);
      expect(values![0], 'MyProject');
      expect(values[1], '2.2');
    });

    test('AgvtoolCommand what-version fail', () async {
      final agvtool = AgvtoolCommand();
      final result = await agvtool
          .process(context: PlayContext(), params: {'action': 'what-version'});
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(
          result.fail!['message']
              .toString()
              .startsWith('There are no Xcode project files in this directory'),
          isTrue);
      expect(result.fail!['_name'], 'wings.agvtool');
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
    });

    test('AgvtoolCommand what-version', () async {
      final agvtool = AgvtoolCommand();
      final result = await agvtool
          .process(context: PlayContext(), params: {'action': 'what-version'});
      expect(result, isNotNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['name'], 'Runner');
      expect(result.result!['version'], '1.15.0');
    });

    test('createArgumentRunner', () {
      final wings = WingsApp();
      final runner = wings.createArgumentRunner();
      expect(runner, isNotNull);
      expect(runner.commands['help'], isNotNull);
      expect(runner.commands['command'], isNotNull);
      expect(runner.commands['playbook'], isNotNull);
      expect(runner.description, 'A Flutter helper tool.');
      expect(runner.executableName, 'wings');
      expect(runner.invocation, 'wings <command> [arguments]');
      expect(runner.usage.startsWith(runner.description), isTrue);

      final command = runner.commands['command'];
      expect(command!, isNotNull);
      expect(command.description, 'command: Runs a command.');
      expect(command.name, 'command');
      expect(command.summary, 'command: Runs a command.');
      expect(command.usage.startsWith(command.description), isTrue);
      print(command.usage);

      expect(command.subcommands.length, 6);
      expect(command.subcommands['wings.agvtool']!.name, 'wings.agvtool');
      expect(command.subcommands['wings.debug']!.name, 'wings.debug');
      expect(command.subcommands['wings.pubspec']!.name, 'wings.pubspec');
      expect(command.subcommands['wings.semver']!.name, 'wings.semver');
      expect(command.subcommands['wings.shell']!.name, 'wings.shell');
      expect(command.subcommands['wings.version']!.name, 'wings.version');
    });
  });
}
