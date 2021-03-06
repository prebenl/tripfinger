import Foundation

class SyncManager {
  
  class func delay(delay: Double, closure: ()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }
  
  class func syncMain(closure: () -> ()) {
    if NSThread.isMainThread() {
      let backgroundThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
      dispatch_sync(backgroundThread, closure)
    } else {
      dispatch_sync(dispatch_get_main_queue(), closure)
    }
  }
  
  class func asyncMain(closure: () -> ()) {
    dispatch_async(dispatch_get_main_queue(), closure)
  }
  
  class func asyncBackground(closure: () -> ()) {
    let backgroundThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    dispatch_async(backgroundThread, closure)
  }
  
  class func synchronized(lock: AnyObject, closure: () -> ()) {
    get_lock(lock)
    closure()
    try! release_lock(lock)
  }

  class func synchronized_throws(lock: AnyObject, closure: () throws -> ()) {
    get_lock(lock)
    try! closure()
    try! release_lock(lock)
  }

  class func synchronized_async(lockQueue: dispatch_queue_t, closure: () -> ()) {
    run_async {
      synchronized(lockQueue, closure: closure)
    }
  }

  class func synchronized_async_throws(lockQueue: dispatch_queue_t, closure: () throws -> ()) {
    run_async {
      synchronized_throws(lockQueue, closure: closure)
    }
  }

  class func block_until_condition(lock: AnyObject, condition: () -> Bool, after: (() -> ())? = nil) {
    var conditionMet = false
    while true {
      synchronized(lock) {
        conditionMet = condition()
        if conditionMet {
          if let after = after {
            after()            
          }
        }
      }      
      if conditionMet {
        break
      }
      else {
        usleep(10 * 1000)
      }
    }
  }
  
  /*
  * The lock must be released in the same thread as it's locked on.
  */
  
  class func get_lock(lock: AnyObject) {
    objc_sync_enter(lock)
  }
  
  class func release_lock(lock: AnyObject) throws {
    let result = objc_sync_exit(lock)
    switch Int(result) {
    case OBJC_SYNC_SUCCESS:
      break
    default:
      print("release result: \(result)")
      throw Error.RuntimeError("Tried to release lock held by another thread.")
    }
  }
  
  class func run_async(closure: () -> ()) {
    let qualityOfServiceClass = DISPATCH_QUEUE_PRIORITY_BACKGROUND
    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
    dispatch_async(backgroundQueue, {
      closure()
    })
  }
  
  class func run_async_throws(closure: () throws -> ()) {
    let qualityOfServiceClass = DISPATCH_QUEUE_PRIORITY_BACKGROUND
    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
    dispatch_async(backgroundQueue, {
      try! closure()
    })
  }

}