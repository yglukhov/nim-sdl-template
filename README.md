This repo is discontinued in favour of [nimx](https://github.com/yglukhov/nimx). No guarantees that it will work with latest versions of everything.

# Cross-platform [SDL](http://libsdl.org) project in [Nim](http://nim-lang.org)

This is a project template that builds and runs on different target platforms.

## Dependencies:
- SDL. Get SDL2 sources, and set ```sdlRoot``` in ```nakefile.nim```
- XCode. Required to build SDL for mac, ios, ios-sim. Not needed for android.
- Android SDK. Set ```androidSdk``` in ```nakefile.nim```
- Android NDK. Set ```androidNdk``` in ```nakefile.nim```
- Ant. Required to package and install on android.

## Setup
- Change appropriate options in ```nakefile.nim```: ```appName```, ```bundleId```, ```javaPackageId```, ```sdlRoot```, ```nimIncludeDir```.
- To run in ios-simulator make sure to set ```iOSSimulatorDeviceId```.

## Building
```
$ nake <task>
```

List available tasks:
```
$ nake help
```

## Feedback
Please feel free to submit pull requests, bug reports, etc.

