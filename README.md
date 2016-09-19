# Fusuma

Fusuma is a Swift library that provides an Instagram-like photo browser and a camera feature with a few line of code.  
You can use Fusuma instead of UIImagePickerController. It also has a feature to take a square-sized photo.

[![Version](https://img.shields.io/cocoapods/v/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![Platform](https://img.shields.io/cocoapods/p/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![CI Status](http://img.shields.io/travis/ytakzk/Fusuma.svg?style=flat)](https://travis-ci.org/ytakzk/Fusuma)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat](https://codebeat.co/badges/287ff7b1-4cda-4384-8780-88e1dbff95cd)](https://codebeat.co/projects/github-com-ytakzk-fusuma)

## Preview
<img src="https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/fusuma.gif" width="340px">

## Images
<img src="https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/shot1.jpg" width="340px">
<img src="https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/shot2.jpg" width="340px">

## Features
- [x] UIImagePickerController alternative
- [x] Cropping images in camera roll
- [x] Taking a square-sized photo and a video using AVFoundation
- [x] Flash: On Off 
- [x] Camera Mode: Front Back 
- [x] Video Mode 

Those features are available just with a few lines of code!

## Installation

Drop in the Classes folder to your Xcode project.  
You can also use CocoaPods or Carthage.

#### Using [CocoaPods](http://cocoapods.org/)

Add `pod 'Fusuma'` to your `Podfile` and run `pod install`. Also add `use_frameworks!` to the `Podfile`.

```
use_frameworks!
pod 'Fusuma'
```

#### Using [Carthage](https://github.com/Carthage/Carthage)

Add `github "ytakzk/Fusuma"` to your `Cartfile` and run `carthage update`. If unfamiliar with Carthage then checkout their [Getting Started section](https://github.com/Carthage/Carthage#getting-started).

```
github "ytakzk/Fusuma"
```

## Fusuma Usage
Import Fusuma ```import Fusuma``` then use the following codes in some function except for viewDidLoad and give FusumaDelegate to the view controller.  

```swift
let fusuma = FusumaViewController()
fusuma.delegate = self
fusuma.availableModes = [.Library, .Camera, .Video]
// ^ If you want to allow users to take video.
self.presentViewController(fusuma, animated: true, completion: nil)
```

### availableModes

Configure which tabs are available to the user by setting `availableModes`. The order is respected

```swift
fusuma.availableModes = [.Camera] // no tabs are shown and camera is selected
fusuma.availableModes = [.Library, .Camera] // (default) library is selected first, camera is to the right
fusuma.availableModes = [.Camera, .Library, .Video] // all modes
```

#### Delegate methods

```swift
// Return the image which is selected from camera roll or is taken via the camera.
func fusuma(fusuma: FusumaViewController, imageSelected image: UIImage, viaMode mode: Int) {
    print("Image selected! :)")
}

// Fusuma was closed without choosing an image.
optional func fusumaClosed(fusuma: FusumaViewController) {
    print("No image chosen :(")
}

// Called just after a video has been selected.
func fusuma(fusuma: FusumaViewController, videoCompletedWithFileURL fileURL: NSURL) {
    print("Video taken! :)")
}

// When camera roll is not authorized, this method is called.
func fusumaCameraRollUnauthorized(fusuma: FusumaViewController) {
  print("Camera roll unauthorized :(")
}
```

#### Colors

```swift
baseTintColor : UIColor   // the default tintColor
tintColor : UIColor       // the active tintColor
backgroundColor : UIColor // the backgroundColor
```

#### Customize Image Output 
You can deselect image crop mode with: 

```swift
cropImage: Bool // default is true for cropping the image
```

## Fusuma for Xamarin
Cheesebaron developed Chafu for Xamarin.  
https://github.com/Cheesebaron/Chafu

## Author
ytakzk  
 [http://ytakzk.me](http://ytakzk.me)

## Contributors
Shrugs
 [https://github.com/Shrugs](https://github.com/Shrugs)
 
## Donation
Your support is welcome through Bitcoin 16485BTK9EoQUqkMmSecJ9xN6E9nhW8ePd
 
## License
Fusuma is released under the MIT license.  
See LICENSE for details.
