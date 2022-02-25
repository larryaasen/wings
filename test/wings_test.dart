/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:test/test.dart';

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

      expect(command.subcommands.length, 4);
      expect(command.subcommands['version']!.name, 'version');
      expect(command.subcommands['pubspec']!.name, 'pubspec');
      expect(command.subcommands['semver']!.name, 'semver');
      expect(command.subcommands['shell']!.name, 'shell');
    });
  });
}
