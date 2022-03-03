/*
 * Copyright (c) 2022 Larry Aasen. All rights reserved.
 */

import 'package:wings/wings.dart';
import 'package:test/test.dart';

void main() {
  group('SemverCommand', () {
    test('empty', () async {
      expect(SemverCommand(), isNotNull);

      final ctx = PlayContext();
      var result = await SemverCommand().process(context: ctx, params: {});
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'],
          'exception: FormatException: Cannot parse empty string into version');
      expect(result.fail!['_name'], 'wings.semver');
    });

    test('parse no version', () async {
      final ctx = PlayContext();
      final params = {'action': 'parse'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'],
          'exception: FormatException: Cannot parse empty string into version');
      expect(result.fail!['_name'], 'wings.semver');
    });

    test('parse invalid version', () async {
      final ctx = PlayContext();
      final params = {'action': 'parse', 'version': 'AAA'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isTrue);
      expect(result.fail, isNotNull);
      expect(result.hasResult, isFalse);
      expect(result.result, isNull);
      expect(result.fail!['message'],
          'exception: FormatException: Not a properly formatted version string');
      expect(result.fail!['_name'], 'wings.semver');
    });

    test('parse invalid valid version with pre release', () async {
      final ctx = PlayContext();
      final params = {'action': 'parse', 'version': '1.2.3-1'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['build'], '');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 3);
      expect((result.result!['preRelease'] as List).length, 1);
      expect((result.result!['preRelease'] as List)[0], '1');
    });

    test('parse invalid valid version with build', () async {
      final ctx = PlayContext();
      final params = {'action': 'parse', 'version': '1.2.3+4'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 3);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('incrementMajor', () async {
      final ctx = PlayContext();
      final params = {'action': 'incrementMajor', 'version': '1.2.3+4'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 2);
      expect(result.result!['minor'], 0);
      expect(result.result!['patch'], 0);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('incrementMinor', () async {
      final ctx = PlayContext();
      final params = {'action': 'incrementMinor', 'version': '1.2.3+4'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 3);
      expect(result.result!['patch'], 0);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('incrementPatch', () async {
      final ctx = PlayContext();
      final params = {'action': 'incrementPatch', 'version': '1.2.3+4'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['build'], '4');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 4);
      expect((result.result!['preRelease'] as List).length, 0);
    });

    test('incrementBuild', () async {
      final ctx = PlayContext();
      final params = {'action': 'incrementBuild', 'version': '1.2.3+4'};
      var result = await SemverCommand().process(context: ctx, params: params);
      expect(result, isNotNull);
      expect(result.didFail, isFalse);
      expect(result.fail, isNull);
      expect(result.hasResult, isTrue);
      expect(result.result, isNotNull);
      expect(result.result!['build'], '5');
      expect(result.result!['major'], 1);
      expect(result.result!['minor'], 2);
      expect(result.result!['patch'], 3);
      expect((result.result!['preRelease'] as List).length, 0);
    });
  });
}
