//
//  EditViewController.swift
//  Music Book
//
//  Created by Sergio on 15.06.2018.
//  Copyright © 2018 Sergio. All rights reserved.
//

import UIKit

class EditViewController: UIViewController {
    
    var recording: Recording!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

extension EditViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recording.notes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Note Cell", for: indexPath)
        if indexPath.row == 0 {
            (cell.viewWithTag(1) as! UIImageView).image = UIImage(named: "Treble Clef")
            cell.viewWithTag(3)?.isHidden = true
        } else {
            if let image = UIImage(named: "\(recording.notes[indexPath.row]!.note)") {
                (cell.viewWithTag(1) as! UIImageView).image = image
                (cell.viewWithTag(2) as! UILabel).text = recording.notes[indexPath.row]?.note.description
            } else {
                (cell.viewWithTag(1) as! UIImageView).image = UIImage(named: "Lines")
                cell.viewWithTag(3)?.isHidden = true
            }
        }
        return cell
    }
}
