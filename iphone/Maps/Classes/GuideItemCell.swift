import Foundation

protocol GuideItemContainerDelegate: class {
  func readMoreClicked()
  func licenseClicked()
  func downloadClicked()
}

class GuideItemCell: UITableViewCell {

  var constraintsAdded = false
  let contentImage = UIImageView()
  let licenseButton = UIButton(type: .System)
  let content = UITextView()
  var imageHeight: CGFloat = UIScreen.mainScreen().bounds.width * 0.75 - 50
  var contentHeight: CGFloat = 100
  var contentHeightConstraint: NSLayoutConstraint!
  let downloadView = UIView()
  let downloadButton = UIButton(type: .System)
  var readMoreButton: UIButton!
  var readMoreButtonHeight: Int!
  var readMoreButtonHeightConstraint: NSLayoutConstraint!
  var readMoreButtonMarginConstraint: NSLayoutConstraint!
  weak var delegate: GuideItemContainerDelegate!
  
  init() {
    super.init(style: .Default, reuseIdentifier: nil)
    
    selectionStyle = .None
    
    content.linkTextAttributes[NSForegroundColorAttributeName] = UIColor.blackColor()
    content.editable = false
    readMoreButton = UIButton(type: .System)
    readMoreButton.setTitle("Read more", forState: .Normal)
    readMoreButton.sizeToFit()
    contentView.addSubview(contentImage)
    
    downloadView.backgroundColor = UIColor.whiteColor()
    downloadView.alpha = 0.6
    downloadView.layer.cornerRadius = 10.0
    downloadView.addSubview(downloadButton)
    contentView.addSubview(content)
    contentView.addSubview(readMoreButton)
    contentView.addSubview(downloadView)
    
    licenseButton.setTitle("Content license", forState: .Normal)
    licenseButton.titleLabel!.font = UIFont.systemFontOfSize(12.0)
    licenseButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
    licenseButton.sizeToFit()
    licenseButton.addTarget(self, action: "navigateToLicense", forControlEvents: .TouchUpInside)
    contentView.addSubview(licenseButton)

    readMoreButton.addTarget(self, action: "readMore", forControlEvents: .TouchUpInside)
    downloadButton.addTarget(self, action: "openDownloadCountry", forControlEvents: .TouchUpInside)
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func updateConstraints() {
    super.updateConstraints()
    if !constraintsAdded {
      var views: [String: UIView] = ["button": downloadButton]
      downloadView.addConstraints("V:|-5-[button]-5-|", forViews: views)
      downloadView.addConstraints("H:|-10-[button]-10-|", forViews: views)
      
      views = ["image": contentImage, "download": downloadView, "text": content, "readMore": readMoreButton, "license": licenseButton]
      contentView.addConstraints("V:|-20-[download]", forViews: views)
      contentView.addConstraints("H:[download]-20-|", forViews: views)

      if !contentImage.hidden {
        contentView.addConstraints("V:[image(\(imageHeight))]", forViews: views)
        contentView.addConstraints("V:|-0-[image]-20-[text]", forViews: views)
        contentView.addConstraints("H:|-0-[image]-0-|", forViews: views)
        contentView.addConstraints("V:[license]-20-[text]", forViews: views)
      } else {
        contentView.addConstraints("V:|-0-[license]-20-[text]", forViews: views)
      }
      contentView.addConstraints("H:[license]-20-|", forViews: ["license": licenseButton])
      contentHeightConstraint = try! contentView.addConstraint("V:[text(100)]", forViews: views)
      
      contentView.addConstraints("H:|-10-[text]-10-|", forViews: views)
      readMoreButtonHeight = Int(readMoreButton.frame.size.height)
      readMoreButtonHeightConstraint = try! contentView.addConstraint("V:[readMore(\(readMoreButtonHeight))]", forViews: views)
      
      contentView.addConstraints("V:[text]-10-[readMore]", forViews: views)
      readMoreButtonMarginConstraint = try! contentView.addConstraint("V:[readMore]-10-|", forViews: views)
      contentView.addConstraints("H:|-14-[readMore]", forViews: views)

      constraintsAdded = true
    }
    
    if readMoreButton.hidden {
      readMoreButtonHeightConstraint.constant = 0
      readMoreButtonMarginConstraint.constant = 0
    }
    else {
      readMoreButtonHeightConstraint.constant = CGFloat(readMoreButtonHeight)
      readMoreButtonMarginConstraint.constant = 10
    }
    contentHeightConstraint.constant = min(8192, contentHeight)
  }
  
  override func prepareForReuse() {
    if (!contentImage.isDescendantOfView(contentView)) {
      contentView.addSubview(contentImage)
    }
    if (!readMoreButton.isDescendantOfView(contentView)) {
      contentView.addSubview(readMoreButton)
    }
  }
  
  func expand() {
    let fixedWidth = UIScreen.mainScreen().bounds.width - 20
    let newSize = content.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
    contentHeight = newSize.height - 20 // last paragraphs margin
    readMoreButton.hidden = true
    setNeedsUpdateConstraints()
    
    content.setContentOffset(CGPointZero, animated: false)
  }
  
  func readMore() {
    delegate.readMoreClicked()
  }
  
  func openDownloadCountry() {
    delegate.downloadClicked()
  }
  
  func setContentFromGuideItem(guideItem: GuideItem) {    
    contentImage.image = UIImage(named: "placeholder-712")
    if guideItem.images.count > 0 {
      
      if guideItem.offline {
        contentImage.clipsToBounds = true
        contentImage.contentMode = UIViewContentMode.ScaleAspectFill
        print("offline url: \(guideItem.images[0].getFileUrl())")
        contentImage.image = UIImage(data: NSData(contentsOfURL: guideItem.images[0].getFileUrl())!)
      }
      else {
        let imageUrl = DownloadService.gcsImagesUrl + guideItem.images[0].url + "-712x534"
        try! contentImage.loadImageWithUrl(imageUrl)
      }
      contentImage.hidden = false
    }
    else {
      contentImage.hidden = true
//      contentImage.removeFromSuperview()
//      contentView.addSubview(contentImage)
    }
    
    // download button
    if guideItem.category == Region.Category.COUNTRY.rawValue {
      let downloaded = DownloadService.isCountryDownloaded(guideItem.name)
      let title = downloaded ? "Downloaded" : "Download"
      downloadButton.setTitle(title, forState: .Normal)
      downloadView.hidden = false
      print("displaying downloadButton")
    } else {
      downloadView.hidden = true
    }
    
    var description = ""
    if let content = guideItem.content {
      description = content      
    }
    
    content.attributedText = description.attributedString(17.0)
    content.sizeToFit()
    content.scrollEnabled = false
    content.setContentOffset(CGPointZero, animated: true)
    
    setNeedsUpdateConstraints()
  }
  
  func navigateToLicense() {
    print("licenseClicked")
    delegate.licenseClicked()
  }
}