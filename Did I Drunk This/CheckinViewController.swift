//
//  CheckinViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 11/11/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

class CheckinViewController: UIViewController {

    // MARK: - Properties
    var beer: Beer!

    @IBOutlet weak var theName: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        theName.text = self.beer.name
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
