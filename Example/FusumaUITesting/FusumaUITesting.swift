//
//  FusumaUITesting.swift
//  FusumaUITesting
//
//  Created by Michael Pantaleon on 2017/12/09.
//  Copyright © 2017 ytakzk. All rights reserved.
//

import XCTest

class FusumaUITesting: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    XCUIApplication().launch()
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testGallery() {
    
    
    
    let app = XCUIApplication()
    app.buttons["SHOW"].tap()

    addUIInterruptionMonitor(withDescription: "Would Like to Access Your Photos") { alert -> Bool in
      let okButton = alert.buttons["OK"]
      if okButton.exists {
        okButton.tap()
        return true
      }
      return false
    }
    // this 2 lines are just hacks for permission alert in xcode9 uitesting
    // check this thread: https://forums.developer.apple.com/thread/86989
    app.swipeUp()
    app.swipeDown()
    //
    
    let collectionViewsQuery = app.collectionViews
    
    // unselect the first one
    collectionViewsQuery.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.tap()
    
    // select the fifth one
    collectionViewsQuery.children(matching: .cell).element(boundBy: 4).children(matching: .other).element.tap()
    
    // done
    app.buttons["ic check"].tap()
    
    let imageView = app.images.matching(.image, identifier: "imageView").element
  
    expectation(for: NSPredicate(format: "exists == 1"),
                evaluatedWith: imageView, handler: nil)
    waitForExpectations(timeout: 10, handler: nil)
    
    expectation(for: NSPredicate(format: "value != nil"),
                evaluatedWith: imageView, handler: nil)
    waitForExpectations(timeout: 10, handler: nil)

  }
}

