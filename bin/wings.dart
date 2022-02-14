import 'package:wings/wings.dart';

void main(List<String> arguments) {
  final playBook = testPlaybook();

  final engine = ProcessEngine();
  engine.run(inputPlaybook: playBook);
}

Playbook testPlaybook() {
  final version = VersionCommand();
  final task = Task(
      name: 'Verify the version',
      command: version,
      params: {"command": "verify", 'pubspecPath': './pubspec.yaml'});
  final play = Play(name: "Versioning", tasks: [task]);
  final playBook = Playbook(plays: [play]);
  return playBook;
}
