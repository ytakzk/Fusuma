## Fusuma

Fusuma is a Swift library that provides an Instagram-like photo browser with a camera feature using only a few lines of code.  
You can use Fusuma instead of UIImagePickerController. It also has a feature to take a square-sized photo.

[![Version](https://img.shields.io/cocoapods/v/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![Platform](https://img.shields.io/cocoapods/p/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![CI Status](http://img.shields.io/travis/ytakzk/Fusuma.svg?style=flat)](https://travis-ci.org/ytakzk/Fusuma)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codebeat](https://codebeat.co/badges/287ff7b1-4cda-4384-8780-88e1dbff95cd)](https://codebeat.co/projects/github-com-ytakzk-fusuma)

## Preview
<img src="./Demo/fusuma.gif?raw=true" width="340px">

## Images
<img src="./Demo/camera_roll.png?raw=true" width="340px">
<img src="./Demo/photo.png?raw=true" width="340px">

## Features
- [x] UIImagePickerController alternative
- [x] Cropping images in camera roll
- [x] Taking a square-sized photo and a video using AVFoundation
- [x] Flash: On & Off 
- [x] Camera Mode: Front & Back 
- [x] Video Mode
- [x] Colors fully customizable

Those features are available just with a few lines of code!

## Installation

#### Manual installation

Download and drop the 'Classes' folder into your Xcode project.  

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

```Swift
let fusuma = FusumaViewController()
fusuma.delegate = self
fusuma.hasVideo = true //To allow for video capturing with .library and .camera available by default
fusuma.cropHeightRatio = 0.6 // Height-to-width ratio. The default value is 1, which means a squared-size photo.
fusuma.allowMultipleSelection = true // You can select multiple photos from the camera roll. The default value is false.
self.presentViewController(fusuma, animated: true, completion: nil)
```

#### Delegate methods

```Swift
// Return the image which is selected from camera roll or is taken via the camera.
func fusumaImageSelected(image: UIImage, source: FusumaMode) {

  print("Image selected")
}

// Return the image but called after is dismissed.
func fusumaDismissedWithImage(image: UIImage, source: FusumaMode) {
        
  print("Called just after FusumaViewController is dismissed.")
}

func fusumaVideoCompleted(withFileURL fileURL: NSURL) {

  print("Called just after a video has been selected.")
}

// When camera roll is not authorized, this method is called.
func fusumaCameraRollUnauthorized() {

  print("Camera roll unauthorized")
}

// Return selected images when you allow to select multiple photos.
func fusumaMultipleImageSelected(images: [UIImage], source: FusumaMode) {

}

// Return an image and the detailed information.
func fusumaImageSelected(_ image: UIImage, source: FusumaMode, metaData: ImageMetadata) {

}
```

#### How To Customize

```Swift
let fusuma = FusumaViewController()
fusuma.delegate = self
// ...
fusumaCameraRollTitle = "CustomizeCameraRollTitle"
fusumaCameraTitle = "CustomizeCameraTitle" // Camera Title
fusumaTintColor: UIColor // tint color
// ...
self.presentViewController(fusuma, animated: true, completion: nil)

```

### Properties

| Prop | Type | Description | Default |
|---|---|---|---|
|**`fusumaBaseTintColor `**|UIColor|Base tint color.|`UIColor.hex("#c9c7c8", alpha: 1.0)`|
|**`fusumaTintColor `**|UIColor|Tint color.|`UIColor.hex("#FCFCFC", alpha: 1.0)`|
|**`fusumaBackgroundColor `**|UIColor|Background color.|`UIColor.hex("#c9c7c8", alpha: 1.0)`|
|**`fusumaCheckImage `**| UIImage | Image of check button.|![](./Sources/Assets.xcassets/ic_check.imageset/ic_check_white_48pt.png)|
|**`fusumaCloseImage `**| UIImage |Image of close button.|![](./Sources/Assets.xcassets/ic_close.imageset/ic_close_white_48pt.png)|
|**`fusumaCropImage `**| Bool |Whether to crop the taken image.| `true` |
|**`fusumaSavesImage `**| Bool |Whether to save the taken image.| `false` |
|**`fusumaCameraRollTitle `**| String |Text of camera roll title.| `"Library"` |
|**`fusumaCameraTitle `**| String |Text of carmera title text.| `Photo` |
|**`fusumaVideoTitle `**| String |Text of video title.| `Video` |
|**`fusumaTitleFont `**| UIFont |Whether to save the taken image.| `UIFont(name: "AvenirNext-DemiBold", size: 15)` |

## Fusuma for Xamarin
Cheesebaron developed Chafu for Xamarin.  
https://github.com/Cheesebaron/Chafu

## Author
ytakzk  
 [https://ytakzk.me](https://ytakzk.me)
 
## Donation
Your support is welcome through Bitcoin 3Ps8tBgz4qn6zVUr5D1wcYrrzYjMgEugqv
 
## License
Fusuma is released under the MIT license.  
See LICENSE for details.
