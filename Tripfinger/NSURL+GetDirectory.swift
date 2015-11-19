//
//  NSURL+GetDirectory.swift
//  Tripfinger
//
//  Created by Preben Ludviksen on 19/11/15.
//  Copyright © 2015 Preben Ludviksen. All rights reserved.
//

import Foundation

extension NSURL {
  class func getDirectory(baseDir: NSSearchPathDirectory, withPath path: String) -> NSURL {
    let libraryPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(baseDir, .UserDomainMask, true)[0])
    let folderPath = libraryPath.URLByAppendingPathComponent(path)
    do {
      try NSFileManager.defaultManager().createDirectoryAtPath(folderPath.path!, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
      NSLog("Unable to create directory \(error.debugDescription)")
    }
    return folderPath
  }
}