## Fusuma

Fusuma is a Swift library that provides an Instagram-like photo browser with a few line of code.  
You can use Fusuma instead of UIImagePickerController. It also has a feature to take a square-sized photo.

[![Version](https://img.shields.io/cocoapods/v/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![Platform](https://img.shields.io/cocoapods/p/Fusuma.svg?style=flat)](http://cocoapods.org/pods/Fusuma)
[![CI Status](http://img.shields.io/travis/ytakzk/Fusuma.svg?style=flat)](https://travis-ci.org/ytakzk/Fusuma)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Preview
<img src="https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/fusuma.gif" width="340px">

## Images
<img src="https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/shot1.jpg" width="340px">
<img src="https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/shot2.jpg" width="340px">

## Installation

Drop in the Classes folder to your Xcode project.  
You can also use cocoapods or Carthage.

#### Using [cocoapods](http://cocoapods.org/)

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

## Demo
![Demo](https://raw.githubusercontent.com/wiki/ytakzk/Fusuma/images/demo.gif)

## Fusuma Usage
Import Fusuma ```import Fusuma``` then use the following codes in some function except for viewDidLoad and give FusumaDelegate to the view controller.  

```
let fusuma = Fusuma()
fusuma.delegate = self
self.presentViewController(fusuma, animated: true, completion: nil)
```

#### Delegate methods
```
// Return the image which is selected from camera roll or is taken via the camera.
func fusumaImageSelected(image: UIImage) {

  print("Image selected")
}

// When camera roll is not authorized, this method is called.
func fusumaCameraRollUnauthorized() {

  print("Camera roll unauthorized")
}
```

#### Colors
```
FSTintColor: UIColor // tint color

FSBackgroundColor: UIColor // background color
```

## Author
ytakzk  
 [http://ytakzk.me](http://ytakzk.me)
 
## License
Fusuma is released under the MIT license.  
See LICENSE for details.
