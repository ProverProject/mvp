import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let store = DependencyStore()
  
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    if let swypeVC = window?.rootViewController as? SwypeViewController {
      swypeVC.store = store
    }
    
    return true
  }
}
