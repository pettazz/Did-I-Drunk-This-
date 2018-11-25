//
//  CheckinViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 11/11/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

import Cosmos
import MBProgressHUD

class CheckinViewController: UIViewController {

    // MARK: - Properties
    var beer: Beer!
    
    let untappdMachine = UntappdService()

    @IBOutlet weak var theName: UILabel!
    @IBOutlet weak var labelBackgroundView: UIImageView!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var ratingValueLabel: UILabel!
    
    @IBAction func checkinButton(_ sender: Any) {
        let progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHUD.isSquare = true
        progressHUD.detailsLabel.text = "Checking In..."
        progressHUD.mode = MBProgressHUDMode.indeterminate
        
        self.performCheckin(progressHUD)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelBackgroundView.image = self.beer.image
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = labelBackgroundView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        labelBackgroundView.addSubview(blurEffectView)
        labelBackgroundView.addGradientLayer(colors: [.clear, .darkGray])
        
        theName.text = self.beer.name
        
        ratingView.rating = self.beer.meRating
        ratingView.didTouchCosmos = didTouchRating
        ratingView.didFinishTouchingCosmos = didFinishTouchingRating
        
        ratingValueLabel.text = String(self.beer.meRating)
    }

    private func didTouchRating(_ rating: Double) {
        ratingValueLabel.text = String(format: "%.2f", rating)
    }
    
    private func didFinishTouchingRating(_ rating: Double) {
        ratingValueLabel.text = String(format: "%.2f", rating)
    }
    
    private func performCheckin(_ progressHUD: MBProgressHUD) {
        let bid = self.beer.id
        let rating = self.ratingView.rating
        
        untappdMachine.checkIn(
            beerID: bid,
            rating: rating,
            onSuccess: {json, rateLimitRemaining in
                progressHUD.mode = MBProgressHUDMode.customView
                progressHUD.isSquare = true
                progressHUD.detailsLabel.text = "Done!"
                progressHUD.customView = UIImageView(image: UIImage(named: "checkmark"))
                progressHUD.hide(animated: true, afterDelay: 1.0)
                
                let when = DispatchTime.now() + 1.0
                DispatchQueue.main.asyncAfter(deadline: when){
                    self.dismiss(animated: true)
                }
            },
            onError: {error, rateLimitRemaining, errorTitle, errorMessage in
                progressHUD.hide(animated: false)
                
                let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .cancel))
                self.present(alert, animated: true, completion: nil)
            }
        )
    }

}
