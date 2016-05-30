//
//  Utilities.swift
//  Pastime
//
//  Created by Niels de Hoog on 30/09/14.
//  Copyright (c) 2014 Proto Venture Technology. All rights reserved.
//

import Foundation
import UIKit

#if DEBUG
    func DLog(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
        NSLog("[\(NSURL(fileURLWithPath: filename).URLByDeletingPathExtension?.lastPathComponent):\(line)] \(function) - \(message)")
    }
#else
    func DLog(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    }
#endif
func ALog(message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    NSLog("[\(NSURL(fileURLWithPath: filename).URLByDeletingPathExtension?.lastPathComponent):\(line)] \(function) - \(message)")
}

func UIColorFromRGB(rgbValue: Int) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

enum ColorPalette: Int {
    case StrongBlue = 0x3d99d1
    case StrongGreen = 0x5cb100
    case StrongOrange = 0xec6234
    case MutedSlate = 0x677686
    case Gum = 0xed7975
    case Tourqoise = 0x61b2ad
    case StrongPink = 0xd4515d
    
    static let allValues = [StrongBlue, StrongGreen, StrongOrange, MutedSlate, Gum, Tourqoise, StrongPink]
    
    static func randomColor() -> UIColor {
        let index = arc4random_uniform(UInt32(ColorPalette.allValues.count))
        return colorAtIndex(Int(index))
    }
    
    static func colorAtIndex(index: Int) -> UIColor {
        let colorValue = ColorPalette.allValues[index]
        return UIColorFromRGB(colorValue.rawValue)
    }
}

/**
* Helper method to delay execution of closure by number of seconds
*/
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

enum Pattern: String {
    case FourTriangles = "fourtriangles"
    case LogoPattern = "logopattern"
    case PatternC = "pattern-C-100-white"
    case PatternD = "pattern-D-100-white"
    case PatternF = "pattern-F-100-white"
    case PatternG = "pattern-G-100-white"
    case PatternH = "pattern-H-100-white"
    case PatternI = "pattern-I-100-white"
    case PatternJ = "pattern-J-100-white"
    case PatternK = "pattern-K-100-white"
    
    static let allValues = [LogoPattern, FourTriangles, PatternC, PatternD, PatternF, PatternG, PatternH, PatternI, PatternJ, PatternK];

    static func randomPatternImage() -> UIImage {
        let index = Int(arc4random_uniform(UInt32(Pattern.allValues.count)))
        let safeIndex = abs(index) >= Pattern.allValues.count ? 0 : index
        let patternName = Pattern.allValues[safeIndex]
        return UIImage(named: patternName.rawValue)!
    }
    
    static func patternImageAtIndex(index: Int) -> UIImage {
        let safeIndex = abs(index) >= Pattern.allValues.count ? 0 : index
        let patternName = Pattern.allValues[safeIndex]
        return UIImage(named: patternName.rawValue)!
    }
}


func hexStringFromColor(color: UIColor) -> String {
    let components = CGColorGetComponents(color.CGColor)
    let r:CGFloat = components[0]
    let g:CGFloat = components[1]
    let b:CGFloat = components[2]

    let rInt:Int = Int(r * 255)
    let gInt:Int = Int(g * 255)
    let bInt:Int = Int(b * 255)
    
    //return String("#%02lX%02lX%02lX", lround(r*255), lround(g*255), lround(b*255))
    return StringWithFormat("#%02lX%02lX%02lX", args: rInt, gInt, bInt)
}

// Launch podcasts app
func launchPodcastsApp() {
    let url  = NSURL(string: "pcast://")
    if UIApplication.sharedApplication().canOpenURL(url!) == true
    {
        UIApplication.sharedApplication().openURL(url!)
    }
}

// Launch iTunes store to audiobooks section
func launchAudioBooksStore() {
    let url = NSURL(string: "https://itunes.apple.com/us/genre/audiobooks/id50000024")
    if UIApplication.sharedApplication().canOpenURL(url!) == true
    {
        UIApplication.sharedApplication().openURL(url!)
    }
}


func StringWithFormat(format : String, args: CVarArgType...) -> String {
    
    return NSString(format: format, arguments: getVaList(args)) as String
}

extension String {
    
    func format(args: CVarArgType...) -> String {
        
        return NSString(format: self, arguments: getVaList(args)) as String
        
    }
}


