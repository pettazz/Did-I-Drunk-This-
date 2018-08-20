//
//  BeerDetailViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/14/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

import Cosmos

class BeerDetailViewController: UIViewController {
    
    //MARK: - Properties
    let untappdMachine = UntappdService()
    
    var beer: Beer?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var labelImage: UIImageView!
    @IBOutlet weak var breweryNameLabel: UILabel!
    @IBOutlet weak var beerStyleLabel: UILabel!
    @IBOutlet weak var abvLabel: UILabel!
    @IBOutlet weak var ibuLabel: UILabel!
    @IBOutlet weak var beerDescriptionLabel: UILabel!
    @IBOutlet weak var ratingDisplay: CosmosView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
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
                if(!beerData["beer_label_hd"].stringValue.isEmpty){
                    self.beer!.image =  beerData["beer_label_hd"].stringValue
                }
                self.beer!.drunk = beerData["auth_rating"].intValue > 0
                self.beer!.style = beerData["beer_style"].stringValue
                self.beer!.abv = beerData["beer_abv"].floatValue
                self.beer!.ibu = beerData["beer_ibu"].intValue
                self.beer!.beerDescription = beerData["beer_description"].stringValue
                
                self.updateBeerView()
            },
            onError: {error in
                self.spinner.stopAnimating()
            }
        )
    }

    private func updateBeerView(){
        nameLabel.text = beer!.name
        
        labelImage.clipsToBounds = true
        labelImage.addGradientLayer(colors: [.clear, .white])
        if(!beer!.image.isEmpty){
            labelImage.af_setImage(
                withURL: URL(string: beer!.image)!,
                placeholderImage: UIImage(named: "beerPlaceholder")!)
        }else{
            labelImage.image = UIImage(named: "beerPlaceholder")
        }
        
        breweryNameLabel.text = beer!.brewery
        beerStyleLabel.text = beer!.style
        abvLabel.text = String(beer!.abv!)
        ibuLabel.text = String(beer!.ibu!)
        beerDescriptionLabel.text = beer!.beerDescription
        ratingDisplay.rating = Double(beer!.meRating)
    }
    
}
