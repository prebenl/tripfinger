import Foundation
import XCTest

class OfflineWithDataTest: XCTestCase {
  
  let app = XCUIApplication()
  var origin: XCUICoordinate!
  
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app.launchArguments.append("TEST")
    app.launchArguments.append("OFFLINEMAP")
    app.launch()
    origin = app.coordinateWithNormalizedOffset(CGVector(dx: 0, dy: 0))
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testNavigateHierarchy() {
    addUIInterruptionMonitorWithDescription("Permission Dialogs") { (alert) -> Bool in
      if alert.buttons["Allow"].exists {
        alert.buttons["Allow"].tap()
      } else if alert.buttons["OK"].exists {
        alert.buttons["OK"].tap()
      }
      return true
    }
    let table = app.tables.element
    let bruneiDownloaded = NSPredicate(format: "value == 'bruneiReady'")
    expectationForPredicate(bruneiDownloaded, evaluatedWithObject: table, handler: nil)
    waitForExpectationsWithTimeout(1200, handler: nil)
    sleep(1)
    app.tap()
    XCTAssertEqual(1, app.tables.cells.count)
    tapWhenHittable(app.tables.staticTexts["Brunei"])
    sleep(2)
    
    shouldNavigateInGuide()
    shouldDoSomeSwiping()
    shouldNavigateToMapAndClickOnLinks()
  }
  
  private func shouldNavigateInGuide() {
    tapWhenHittable(app.buttons["Read more"])
    tapWhenHittable(app.tables.staticTexts["History"])
    tapWhenHittable(app.navigationBars["History"].buttons["Brunei"])
    tapWhenHittable(app.tables.staticTexts["Food and drinks"])
    waitUntilExists(app.tables.staticTexts["Kaizen Sushi"])
    sleep(1)
    XCTAssertEqual(2, app.tables.cells.count)
    tapWhenHittable(app.navigationBars["Food and drinks"].buttons["Brunei"])
    tapWhenHittable(app.tables.staticTexts["Bandar"])
    tapWhenHittable(app.tables.staticTexts["Food and drinks"])
    tapWhenHittable(app.navigationBars["Food and drinks"].buttons["Bandar"])
    tapWhenHittable(app.navigationBars["Bandar"].buttons["Brunei"])
    tapWhenHittable(app.tables.staticTexts["Transportation"])
    tapWhenHittable(app.tables.staticTexts["Airports"])
    sleep(1)
    XCTAssertEqual(1, app.tables.cells.count)
    tapWhenHittable(app.tables.staticTexts["Brunei International Airport"])
    waitUntilExists(app.tables.textViews["info@airport.brunei"])
    let busLinkCoords = origin.coordinateWithOffset(CGVector(dx: 81.0, dy: 449.0))
    busLinkCoords.pressForDuration(0.2)
    tapWhenHittable(app.navigationBars["Bus station"].buttons["Back"])
    waitUntilExists(app.tables.textViews["info@airport.brunei"])
    
    tapWhenHittable(app.navigationBars["Brunei International Airport"].buttons["Back"])
    tapWhenHittable(app.navigationBars["Airports"].buttons["Transportation"])
    tapWhenHittable(app.navigationBars["Transportation"].buttons["Brunei"])
    
    // try to click a link
    scrollUp(2)
    let tableCoord = app.tables.element.coordinateWithNormalizedOffset(CGVector(dx: 0, dy: 0))
    var linkCoord = tableCoord.coordinateWithOffset(CGVector(dx: 65.0, dy: (118.0 + 64)))
    linkCoord.pressForDuration(0.2)
    tapWhenHittable(app.navigationBars["Bandar"].buttons["Brunei"])
    
    tapWhenHittable(app.tables.staticTexts["History"])
    linkCoord = tableCoord.coordinateWithOffset(CGVector(dx: 36.5, dy: (63.5 + 64)))
    linkCoord.pressForDuration(0.2)
    tapWhenHittable(app.navigationBars["Bandar"].buttons["History"])
    tapWhenHittable(app.navigationBars["History"].buttons["Brunei"])
  }
  
  private func shouldDoSomeSwiping() {
    
    // do some swiping
    tapWhenHittable(app.tables.staticTexts["Attractions"])
    waitUntilNotHittable(app.staticTexts["Loading..."])
    let frontCard = app.otherElements.elementMatchingType(.Other, identifier: "frontCard")
    frontCard.swipeRight()
    app.navigationBars["Attractions"].buttons["Brunei"].tap()
  }
  
  private func shouldNavigateToMapAndClickOnLinks() {
    
    // go to brunei map and download it if necessary
    tapWhenHittable(app.tables.staticTexts["Bandar"])
    tapWhenHittable(app.tables.staticTexts["Transportation"])
    tapWhenHittable(app.navigationBars["Transportation"].buttons["Map"])
    app.tap()
    waitUntilHasValue("Transportation ", element: app.textFields["Search"])
    sleep(4)
    if app.buttons["Download Map"].exists {
      tapWhenHittable(app.buttons["Download Map"])
      sleep(2)
    }
    waitUntilNotHittable(app.staticTexts["Brunei"])
    sleep(2)
    
    // click on a listing and on a region-link in a description
    let busStationPoint = origin.coordinateWithOffset(CGVector(dx: 200, dy: 346.5))
    busStationPoint.tap()
    sleep(1)
    let expandInfoPoint = origin.coordinateWithOffset(CGVector(dx: 187, dy: 572.5))
    expandInfoPoint.tap()
    sleep(1)
    let seriaLinkPoint = origin.coordinateWithOffset(CGVector(dx: 121.5, dy: 545))
    seriaLinkPoint.pressForDuration(0.2)
    sleep(2)
    tapWhenHittable(app.navigationBars["Seria"].buttons["Brunei"])
    tapWhenHittable(app.tables.staticTexts["Bandar"])

    // click on a listing and on an offline listing-link in a description
    tapWhenHittable(app.tables.staticTexts["Transportation"])
    tapWhenHittable(app.navigationBars["Transportation"].buttons["Map"])
    sleep(2)
    busStationPoint.tap()
    sleep(1)
    expandInfoPoint.tap()
    sleep(1)
    let airportLinkPoint = origin.coordinateWithOffset(CGVector(dx: 173, dy: 548))
    airportLinkPoint.pressForDuration(0.2)
    sleep(2)
    expandInfoPoint.tap()
    sleep(1)
    waitUntilExists(app.tables.textViews["info@airport.brunei"])
  }
}