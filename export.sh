#!/bin/bash

if [ ! -f project.godot ]; then
	echo "Running from an invalid location; aborting" >&2
	exit 1
fi

if [ -n "${1}" ]; then
	echo "Setting version text to '${1}'" >&2
	echo "${1}" > version.txt
fi

echo "Importing project resources" >&2
godot4 -v --headless --import project.godot
[ $? == 0 ] || exit 1

echo "Cleaning build outputs" >&2
rm -rf build/BrackeysJam12-Linux-amd64/
[ $? == 0 ] || exit 1
rm -rf build/BrackeysJam12-Windows-amd64/
[ $? == 0 ] || exit 1
rm -rf build/BrackeysJam12-Linux.zip
[ $? == 0 ] || exit 1
rm -rf build/BrackeysJam12-Windows.zip
[ $? == 0 ] || exit 1

echo "Creating build directories" >&2
mkdir -p build/BrackeysJam12-Linux-amd64/
[ $? == 0 ] || exit 1
mkdir -p build/BrackeysJam12-Windows-amd64/
[ $? == 0 ] || exit 1

echo >&2
echo "Starting Linux export" >&2
godot4 -v --headless --export-release BrackeysJam12-Linux-amd64 build/BrackeysJam12-Linux-amd64/game
[ $? == 0 ] || exit 1
echo >&2
echo "Starting Windows export" >&2
godot4 -v --headless --export-release BrackeysJam12-Windows-amd64 build/BrackeysJam12-Windows-amd64/game.exe
[ $? == 0 ] || exit 1

echo >&2
echo "Archiving exports" >&2
pushd build/ >/dev/null
echo "BrackeysJam12-Linux.zip" >&2
zip -r BrackeysJam12-Linux.zip BrackeysJam12-Linux-amd64
[ $? == 0 ] || exit 1
echo "BrackeysJam12-Windows.zip" >&2
zip -r BrackeysJam12-Windows.zip BrackeysJam12-Windows-amd64
[ $? == 0 ] || exit 1
popd >/dev/null
