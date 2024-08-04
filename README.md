<p align="center" width="100%">
<img src="assets/icon/app_icon_transparent.png" width="20%" height="20%">
<h1 align="center">IronFlow</h1>
<h3 align="center">Cross-platform mobile app for strength training progress tracking.</h3>

[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![GitHub Downloads](https://img.shields.io/github/downloads/andreped/IronFlow/total?label=GitHub%20downloads&logo=github)](https://github.com/andreped/IronFlow/releases)

**IronFlow** was developed to allow free, private, and seemless tracking of training progress and activities.
</div>

<p align="center" width="100%">
<img src="assets/snapshots/log.png" width="22%" height="22%"> <img src="assets/snapshots/table.png" width="22%" height="22%"> <img src="assets/snapshots/visualize.png" width="22%" height="22%"> <img src="assets/snapshots/summary.png" width="22%" height="22%">
</p>

## Continuous integration

| Build Type | Status |
| - | - |
| **Build APK** | ![CI](https://github.com/andreped/IronFlow/workflows/Build%20APK/badge.svg) |
| **Build IPA** | ![CI](https://github.com/andreped/IronFlow/workflows/Build%20IPA/badge.svg) |

## Getting started

A cross-platform mobile app was developed to test the produced solutions. Installers for both
Android (.apk) and iOS (.ipa) were developed. To install the app, a different approach is required
on Android and iOS.

### Android

1. On the mobile device (e.g., Samsung), go to Settings > About phone > Software information > Click the `Build number` 5 times. Then say `yes` to enable developer mode.
2. On the mobile device, download the APK from [releases](https://github.com/andreped/IronFlow/releases).
3. Go to Files > Downloads and click the downloaded file. After uncompression click the `*.apk` file.
4. You should get prompted _"Unsafe app blocked"_. Click on `More details` and press `Install anyways`.

Then simply use the app as you would with any other Android app.

### iOS

**DISCLAIMER:** _We currently do not own an Apple Developer Certificate, thus we cannot sign the IPA.
This has to be done before the IPA can be used to install the app on iOS._

1. Connect the mobile device (e.g., iPhone) to a desktop device (e.g., macbook) with USB cable.
2. On the desktop device, download the IPA from [releases](https://github.com/andreped/IronFlow/releases).
3. On the desktop device, go to `Finder`, and then unlock the mobile device. The phone should then be accessbile from the left-hand side in Finder, and click on it.
4. On the desktop device, open a new `Finder` window, go to `Downloads` and uncompress the downloaded file. Drag-and-drop the `.ipa` file over the iPhone Finder window.
5. After a few seconds, the mobile app should then be installed (you can see the progress on both the mobile device and in the Finder mobile app window).
6. On the mobile device, to allow the app to be used, go to `General` > `VPN & Device Management` and click on the app and `Allow`.

Then simply use the app as you would with any other iOS app.

## License

This project has MIT License.

## Acknowledgements

To reduce development time and get experience with Copilots, 
this Flutter application was heavily assisted by OpenAI's Chat-GPT,
primarily using GPT-4/4o/4o-mini.
