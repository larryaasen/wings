import 'package:version/version.dart';

import '../wings.dart';

class SemverCommand extends WingsCommand {
  @override
  String get name => 'semver';

  @override
  // TODO: implement docDescription
  String get docDescription => throw UnimplementedError();

  @override
  // TODO: implement docExamples
  String get docExamples => throw UnimplementedError();

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
    if (params['command'] == "parse") {
      final versionString = params['version'];
      try {
        Version version = Version.parse(versionString);
        final result = {
          'build': version.build,
          'major': version.major,
          'minor': version.minor,
          'patch': version.patch,
          'preRelease': version.preRelease,
        };
        return Future.value(CommandResult.result(result));
      } catch (e) {
        return Future.value(fail({'message': 'exception'}));
      }
    } else {
      return Future.value(fail({'message': 'unknown command'}));
    }
  }
}
