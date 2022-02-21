build_cli:
	rm -f bin/wings; dart compile exe bin/wings.dart --output bin/wings

build_run:
	dart run bin/wings.dart

run:
	bin/wings
