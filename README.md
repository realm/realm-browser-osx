# Realm Browser
Realm Browser is a small utility for Mac OS X that lets you open .realm files to view and modify their contents.

![Realm Browser](screenshot.jpg)

[![Build Status](https://travis-ci.org/realm/realm-browser-osx.svg?branch=master)](https://travis-ci.org/realm/realm-browser-osx)

## Installing

### Mac App Store (Recommended)
Download the app in the [Mac App Store](https://itunes.apple.com/us/app/realm-browser/id1007457278?mt=12).

### Manual Build
Download the project and build it using Xcode. Realm Browser uses [CocoaPods](https://cocoapods.org) to manage its external dependicies, so having CocoaPods installed on your system as well, while not necessary is preferred.

### GitHub Releases
Download the built app in [releases](https://github.com/realm/realm-browser-osx/releases/).

### Homebrew Cask
If you have [homebrew](http://brew.sh) installed, simply run `brew cask install realm-browser`. You may need to run `brew cask update` if homebrew says `realm-browser` is not available.

## Design Goals
The main design goals of Realm Browser are:
* Allow quick and easy access to the contents of .realm files.
* Be able to modify the contents of .realm files without needing to use code.
* Make it easier to automatically generate Realm Object source files.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for more details!

## License
The source code to Realm Browser is licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
