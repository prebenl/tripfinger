import RealmSwift
import MBProgressHUD

class GuideItemController: TableController {
  
  var contextSwitched = false
  var guideItemExpanded = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print("view.translatesAutoresizingMaskIntoConstraints: \(view.translatesAutoresizingMaskIntoConstraints)")
    
    automaticallyAdjustsScrollViewInsets = false
    let mapButton = UIBarButtonItem(image: UIImage(named: "maps_icon"), style: .Plain, target: self, action: "navigateToMap")
    mapButton.accessibilityLabel = "Map"
    let searchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "navigateToSearch")
    navigationItem.rightBarButtonItems = [searchButton, mapButton]
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 44.0;
    tableView.tableHeaderView = UIView.init(frame: CGRectMake(0.0, 0.0, tableView.bounds.size.width, 0.01))
    tableView.tableFooterView = UIView.init(frame: CGRectZero)
    
    updateUI()
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.Portrait
  }
  
  func navigationFailure() {
    self.navigationController?.popViewControllerAnimated(true)
    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    loadingNotification.mode = MBProgressHUDMode.CustomView
    loadingNotification.labelText = "Connection failed"
    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue()) {
      MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    }
  }

  
  func updateUI() {
    // if nil, we are in offline mode, changeRegion returned immediately, and viewdidload will trigger this method
    if let tableView = tableView {
      navigationItem.title = session.currentItem.name
      
      populateTableSections()
      tableView.reloadData {
        self.tableView.contentOffset = CGPointZero
      }
    }
  }
  
  override func viewWillDisappear(animated: Bool) {
    backButtonAction(self)
  }
  
//  func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//    print("will display: \(cell.textLabel?.text)")
//  }
//  
//  func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//    print("ended displaying: \(cell.textLabel?.accessibilityLabel)")
//    cell.textLabel?.accessibilityLabel = nil
//    cell.textLabel?.accessibilityIdentifier = nil
//    cell.textLabel?.text = nil
//  }
  
  func backButtonAction(viewController: UIViewController) {
    print("back button action")
    if TripfingerAppDelegate.navigationController.viewControllers.indexOf(viewController) == nil && !contextSwitched {
        guideItemExpanded = false
        let parentViewController = TripfingerAppDelegate.navigationController.viewControllers.last as? GuideItemController
        let failure = {
          fatalError("we're stranded")
        }
        session.moveBackInHierarchy(failure) {
          // sometimes we will get a ListingsController, but it's not possible to move to sections by search,
          // so it will note be necessary to update UI upon moving back
          if let parentViewController = parentViewController {
            dispatch_async(dispatch_get_main_queue()) {
              print("calling updateUI on parent")
              parentViewController.updateUI()
            }
          }
        }
    }
  }
  
  func downloadClicked() {}
}

extension GuideItemController: GuideItemContainerDelegate {
  
  func readMoreClicked() {
    guideItemExpanded = true
    populateTableSections()
    tableView.reloadData()
  }
  
  func licenseClicked() {
    let licenseController: UIViewController
    if session.currentItem.textLicense == nil || session.currentItem.textLicense == "" && session.currentSection != nil {
      licenseController = LicenseController(textItem: session.currentRegion.item(), imageItem: session.currentItem)
    } else {
      licenseController = LicenseController(textItem: session.currentItem, imageItem: session.currentItem)
    }
    licenseController.edgesForExtendedLayout = .None // offset from navigation bar
    navigationController!.pushViewController(licenseController, animated: true)
  }
  
  func populateTableSections() {}
  
  func jumpToRegion(regionId: String) {
    let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    loadingNotification.mode = MBProgressHUDMode.Indeterminate
    loadingNotification.labelText = "Loading"
    let failure = {
      MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
      let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      loadingNotification.mode = MBProgressHUDMode.CustomView
      loadingNotification.labelText = "Connection failed"
      let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
      dispatch_after(delayTime, dispatch_get_main_queue()) {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
      }
    }
    TripfingerAppDelegate.jumpToRegion(regionId, failure: failure) {
      MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    }
  }
}

// MARK: - Navigation
extension GuideItemController {
  
  func navigateToSection(object: AnyObject) {
    print("Navigation to section")
    let section = object as! GuideText
    
    let sectionController = SectionController(session: session)
    sectionController.edgesForExtendedLayout = .None // offset from navigation bar
    sectionController.navigationItem.title = title
    sectionController.guideItemExpanded = true
    navigationController!.pushViewController(sectionController, animated: true)
    
    session.changeSection(section, failure: navigationFailure) {
      sectionController.updateUI()
    }
  }

  func navigateToSearch() {
    let vc = MapsAppDelegateWrapper.getMapViewController()
    navigationController!.pushViewController(vc, animated: true)
    MapsAppDelegateWrapper.openSearch()
  }
  
  func navigateToMap() {
    let vc = MapsAppDelegateWrapper.getMapViewController()
    navigationController!.pushViewController(vc, animated: true)
    
    if let region = self.session.currentRegion {
      FrameworkService.navigateToRegionOnMap(region)
    }
  }
}
