import 'dart:io';

Future<String> copyToTmp(String path) async {
  final systemTempDir = Directory.systemTemp.path;
  final newPath = '$systemTempDir/__wings_temp';
  final newFile = await File(path).copy(newPath);
  return newFile.path;
}
