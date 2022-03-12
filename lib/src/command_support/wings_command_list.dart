import '../commands/agvtool_command.dart';
import '../commands/debug_command.dart';
import '../commands/pubspec_command.dart';
import '../commands/semver_command.dart';
import '../commands/shell_command.dart';
import '../commands/version_command.dart';

import 'wings_commands.dart';

class WingsCommandList {
  List<WingsCommand> get all => [
        AgvtoolCommand(),
        DebugCommand(),
        PubspecCommand(),
        SemverCommand(),
        ShellCommand(),
        VersionCommand(),
      ];
}
