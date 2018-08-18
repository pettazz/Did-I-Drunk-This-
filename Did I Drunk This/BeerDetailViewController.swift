//
//  BeerDetailViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/14/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

class BeerDetailViewController: UIViewController {
    
    //MARK: - Properties
    let untappdMachine = UntappdService()
    
    var beer: Beer?
    
    @IBOutlet weak var bid: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var drunkLabel: UILabel!
    @IBOutlet weak var labelImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bid.text = String(beer!.id)
        navigationItem.title = beer!.name
        //navigationItem.largeTitleDisplayMode = .never
        
        fetchBeerDetails()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Private Methods
    private func fetchBeerDetails(){
        untappdMachine.beerDetails(
            beerID: self.beer!.id,
            onSuccess: {json in
                self.spinner.stopAnimating()
                
                let beerData = json["response"]["beer"]
                
                self.beer!.brewery = beerData["brewery"]["brewery_name"].stringValue
                self.beer!.image = beerData["beer_label_hd"].stringValue.isEmpty ?
                    beerData["beer_label"].stringValue :
                    beerData["beer_label_hd"].stringValue
                self.beer!.drunk = beerData["auth_rating"].intValue > 0
                
                print(beerData["checkins"])
                
                self.updateBeerView()
            },
            onError: {error in
                self.spinner.stopAnimating()
            }
        )
    }

    private func updateBeerView(){
        nameLabel.text = beer!.name
        drunkLabel.text = beer!.drunk ? "YEP" : "NOPE"
        if(!beer!.image.isEmpty){
            labelImage.af_setImage(
                withURL: URL(string: beer!.image)!,
                placeholderImage: UIImage(named: "beerPlaceholder")!)
        }else{
            labelImage.image = UIImage(named: "beerPlaceholder")
        }
    }
    
}
