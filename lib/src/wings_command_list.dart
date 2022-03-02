import 'package:wings/src/wings_commands.dart';

import 'pubspec_command.dart';
import 'semver_command.dart';
import 'shell_command.dart';
import 'version_command.dart';

class WingsCommandList {
  List<WingsCommand> get all => [
        VersionCommand(),
        PubspecCommand(),
        SemverCommand(),
        ShellCommand(),
      ];
}
