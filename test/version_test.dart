/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:wings/wings.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('VersionCommand', () {
    test('no params', () async {
      expect(VersionCommand(), isNotNull);

      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: {});
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'], 'unknown action');
      expect(result.fail!['_name'], 'version');
    });

    test('verify missing directory', () async {
      final params = {'action': 'verify'};
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'], 'missing path');
      expect(result.fail!['_name'], 'pubspec');
    });

    test('verify missing pubspec file', () async {
      final params = {'action': 'verify', 'pubspecPath': '/'};
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'],
          'exception: FileSystemException: Cannot open file, path = \'/\' (OS Error: Is a directory, errno = 21)');
      expect(result.fail!['_name'], 'pubspec');
    });

    test('verify file', () async {
      final params = {
        'action': 'verify',
        'pubspecPath': 'test/pubspecs/test1_pubspec.yaml'
      };
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['version'], '1.2.3+4');
      expect(result.result!['valid'], isTrue);
      expect(result.result!['androidValid'], isTrue);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 3);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('bump major', () async {
      final params = {
        'action': 'bump',
        'type': 'major',
        'pubspecPath': await copyToTmp('test/pubspecs/test1_pubspec.yaml')
      };
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['version'], '2.0.0+4');
      expect(result.result!['valid'], isTrue);
      expect(result.result!['androidValid'], isTrue);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 2);
      expect(result.result!['minor'], 0);
      expect(result.result!['patch'], 0);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('bump minor', () async {
      final params = {
        'action': 'bump',
        'type': 'minor',
        'pubspecPath': await copyToTmp('test/pubspecs/test1_pubspec.yaml')
      };
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['version'], '1.3.0+4');
      expect(result.result!['valid'], isTrue);
      expect(result.result!['androidValid'], isTrue);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 3);
      expect(result.result!['patch'], 0);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('bump patch', () async {
      final params = {
        'action': 'bump',
        'type': 'patch',
        'pubspecPath': await copyToTmp('test/pubspecs/test1_pubspec.yaml')
      };
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['version'], '1.2.4+4');
      expect(result.result!['valid'], isTrue);
      expect(result.result!['androidValid'], isTrue);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 4);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('bump build', () async {
      final params = {
        'action': 'bump',
        'type': 'build',
        'pubspecPath': await copyToTmp('test/pubspecs/test1_pubspec.yaml')
      };
      final ctx = PlayContext();
      var result = await VersionCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['version'], '1.2.3+5');
      expect(result.result!['valid'], isTrue);
      expect(result.result!['androidValid'], isTrue);
      expect(result.result!['build'], '5');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 3);
      expect((result.result!['preRelease'] as List).length, 0);
    });
  });
}
