Vendored from flutter_audio_toolkit 1.0.0 on pub.dev (see LICENSE).

Local change: add iOS Swift Package Manager packaging and move the existing
Swift source and privacy manifest to the standard package layout. The podspec
uses the same files, preserving CocoaPods support. Runtime code is unchanged.
Other platforms are copied unchanged.

Replace this local package with a published release once upstream supports
Swift Package Manager, after checking audio conversion and trimming.
