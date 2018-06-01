//
//  Extentions.swift
//  Music Book
//
//  Created by Sergio on 28/05/18.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension LibraryViewController {
    func deselectAllWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LibraryViewController.deselectAllCells))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func deselectAllCells() {
        if let selected = selectedRow {
            (tableView.cellForRow(at: selected) as! RecordingTableViewCell).isExpanded = false
            (tableView.cellForRow(at: selected) as! RecordingTableViewCell).title.resignFirstResponder()
        }
        selectedRow = nil
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

extension UIBarButtonSystemItem {
    func image() -> UIImage? {
        let tempItem = UIBarButtonItem(barButtonSystemItem: self, target: nil, action: nil)
        
        // add to toolbar and render it
        let bar = UIToolbar()
        bar.setItems([tempItem],
                     animated: false)
        bar.snapshotView(afterScreenUpdates: true)
        
        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView
        for view in itemView.subviews {
            if let button = view as? UIButton,
                let image = button.imageView?.image {
                return image.withRenderingMode(.alwaysTemplate)
            }
        }
        
        return nil
    }
}
