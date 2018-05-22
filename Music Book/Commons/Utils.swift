/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

//*****************************************************************
// MARK: - Extensions
//*****************************************************************

public extension UIColor {
  public class func fuberBlue()->UIColor {
    struct C {
      static var c : UIColor = UIColor(red: 15/255, green: 78/255, blue: 101/255, alpha: 1)
    }
    return UIColor(red: 40/255, green: 56/255, blue: 77/255, alpha: 1) // UIColor(red: 31/255, green: 36/255, blue: 53/255, alpha: 1) // C.c
  }
  
  public class func fuberLightBlue()->UIColor {
    struct C {
      static var c : UIColor = UIColor(red: 77/255, green: 181/255, blue: 217/255, alpha: 1)
    }
    return UIColor(red: 40/255, green: 56/255, blue: 77/255, alpha: 1) // C.c
  }
}

//*****************************************************************
// MARK: - Helper Functions
//*****************************************************************

public func delay(_ delay:Double, closure:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(
    deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
