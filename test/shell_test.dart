/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:wings/wings.dart';
import 'package:test/test.dart';

void main() {
  group('ShellCommand', () {
    test('empty', () async {
      expect(ShellCommand(), isNotNull);

      final ctx = PlayContext();
      var result = await ShellCommand().process(context: ctx, params: {});
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'], 'missing cmd');
      expect(result.fail!['_name'], 'shell');
    });

    test('run ls', () async {
      final params = {'cmd': 'ls pubspec.yaml'};
      final ctx = PlayContext();
      var result = await ShellCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['exitCode'], '0');
      expect(result.result!['stdout'], 'pubspec.yaml\n');
      expect(result.result!['stderr'], '');
      expect(result.result!['_name'], 'shell');
    });

    test('run echo', () async {
      final params = {'cmd': 'echo hello'};
      final ctx = PlayContext();
      var result = await ShellCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['exitCode'], '0');
      expect(result.result!['stdout'], 'hello\n');
      expect(result.result!['stderr'], '');
      expect(result.result!['_name'], 'shell');
    });

    test('run dart --version', () async {
      final params = {'cmd': 'dart --version'};
      final ctx = PlayContext();
      var result = await ShellCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['exitCode'], '0');
      expect(
          result.result!['stdout'].toString().startsWith('Dart SDK version:'),
          isTrue);
      expect(result.result!['stderr'], '');
      expect(result.result!['_name'], 'shell');
    });
  });
}
