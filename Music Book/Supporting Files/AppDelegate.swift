//
//  AppDelegate.swift
//  Music Book
//
//  Created by Sergio on 24.04.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit
import AVFoundation
import AudioKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        /* Manage Record Permission */
        switch AVAudioSession.sharedInstance().recordPermission() {
        case .granted:
            os_log("Record Permission is Granted", log: OSLog.default, type: .info)
            do {
                try AKSettings.setSession(category: .playAndRecord, with: [.allowBluetoothA2DP, .mixWithOthers, .allowAirPlay, .defaultToSpeaker])
                AudioManager.shared.start()
            } catch {
                AKLog("ERROR: Couldn't set session category (\(error.localizedDescription))")
            }
        case .denied:
            os_log("Record Permission is Denied", log: OSLog.default, type: .fault)
        case .undetermined:
            os_log("Record Permission is Undetermined", log: OSLog.default, type: .info)
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                
            }
        }

        
        /* Microphone permission request */
//        let session = AVAudioSession.sharedInstance()
//        do {
//            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
//            try session.setActive(true)
//
//            session.requestRecordPermission() { (granted: Bool) -> Void in
//                if granted {
//                    DataStorage.applicationHasMicrophoneAccess = true
//                } else {
//                    DataStorage.applicationHasMicrophoneAccess = false
//                }
//            }
//        } catch let error {
//            debugPrint(error.localizedDescription)
//        }
        
        /* Splash screen animation */
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//        self.window!.backgroundColor = UIColor.flatNavyBlueDark
//        self.window!.makeKeyAndVisible()
//
//        // rootViewController from StoryBoard
//        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let navigationController = mainStoryboard.instantiateViewController(withIdentifier: "mainViewController")
//        self.window!.rootViewController = navigationController
        
//        // logo mask
//        navigationController.view.layer.mask = CALayer()
//        navigationController.view.layer.mask?.contents = UIImage(named: "Record Disabled.png")!.cgImage
//        navigationController.view.layer.mask?.bounds = CGRect(x: 0, y: 0, width: 60, height: 60)
//        navigationController.view.layer.mask?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        navigationController.view.layer.mask?.position = CGPoint(x: navigationController.view.frame.width / 2, y: navigationController.view.frame.height / 2)
//
//        // logo mask background view
//        let maskBgView = UIView(frame: navigationController.view.frame)
//        maskBgView.backgroundColor = UIColor.flatNavyBlueDark
//        navigationController.view.addSubview(maskBgView)
//        navigationController.view.bringSubview(toFront: maskBgView)
//
//        // logo mask animation
//        let transformAnimation = CAKeyframeAnimation(keyPath: "bounds")
//        transformAnimation.delegate = self as? CAAnimationDelegate
//        transformAnimation.duration = 1
//        transformAnimation.beginTime = CACurrentMediaTime() + 1 //add delay of 1 second
//        let initalBounds = NSValue(cgRect: (navigationController.view.layer.mask?.bounds)!)
//        let secondBounds = NSValue(cgRect: CGRect(x: 0, y: 0, width: 50, height: 50))
//        let finalBounds = NSValue(cgRect: CGRect(x: 0, y: 0, width: 2000, height: 2000))
//        transformAnimation.values = [initalBounds, secondBounds, finalBounds]
//        transformAnimation.keyTimes = [0, 0.5, 1]
//        transformAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut), CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
//        transformAnimation.isRemovedOnCompletion = false
//        transformAnimation.fillMode = kCAFillModeForwards
//        navigationController.view.layer.mask?.add(transformAnimation, forKey: "bounds")
//
//        // logo mask background view animation
//        UIView.animate(withDuration: 0.1,
//                                   delay: 1.35,
//                                   options: UIViewAnimationOptions.curveEaseIn,
//                                   animations: {
//                                    maskBgView.alpha = 0.0
//        },
//                                   completion: { finished in
//                                    maskBgView.removeFromSuperview()
//        })
 
        // root view animation
//        UIView.animate(withDuration: 0.25,
//                                   delay: 1.3,
//                                   options: [],
//                                   animations: {
//                                    self.window!.rootViewController!.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
//        },
//                                   completion: { finished in
//                                    UIView.animate(withDuration: 0.3,
//                                                               delay: 0.0,
//                                                               options: [.curveEaseInOut],
//                                                               animations: {
//                                                                self.window!.rootViewController!.view.transform = .identity
//                                    },
//                                                               completion: nil
//                                    )
//        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

