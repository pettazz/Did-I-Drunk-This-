//
//  BeerDetailViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/14/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

import Alamofire
import AlamofireImage
import Cosmos
import UIImageColors

class BeerDetailViewController: UIViewController {
    
    //MARK: - Properties
    let untappdMachine = UntappdService()
    var colors = UIImageColors(background: .darkGray, primary: .white, secondary: .gray, detail: .orange)
    
    var beer: Beer?
    var beerLabelImage: UIImage?
    
    @IBOutlet weak var scrollContainerView: UIScrollView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var labelImage: UIImageView!
    @IBOutlet weak var breweryNameLabel: UILabel!
    @IBOutlet weak var beerStyleLabel: UILabel!
    @IBOutlet weak var abvLabel: UILabel!
    @IBOutlet weak var ibuLabel: UILabel!
    @IBOutlet weak var beerDescriptionLabel: UILabel!
    @IBOutlet weak var ratingDisplay: CosmosView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func unwindSegueToBeerSearch(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToBeerSearch", sender: self)
    }
    
    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        scrollContainerView.layer.borderWidth = 1
        scrollContainerView.layer.shadowOpacity = 0.9
        scrollContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        scrollContainerView.layer.shadowRadius = 1
        scrollContainerView.layer.masksToBounds = false
        scrollContainerView.layer.cornerRadius = 3
        
        nameLabel.text = beer!.name
        breweryNameLabel.text = beer!.brewery
        ratingDisplay.rating = Double(beer!.meRating)
        labelImage.image = beer!.image
        
        self.colors = labelImage.image!.getColors(quality: .low)
        self.updateColors()
        
        fetchBeerDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = self.colors.background.isLight()! ? .default : .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Private Methods
    private func updateColors(){
        labelImage.addGradientLayer(colors: [.clear, colors.background])
        self.view.backgroundColor = colors.background
        navigationController!.navigationBar.barTintColor = colors.background
        nameLabel.textColor = colors.primary
        breweryNameLabel.textColor = colors.detail
        beerStyleLabel.textColor = colors.secondary
        abvLabel.textColor = colors.secondary
        ibuLabel.textColor = colors.secondary
        beerDescriptionLabel.textColor = colors.secondary
        
        scrollContainerView.backgroundColor = colors.background
        scrollContainerView.layer.borderColor = colors.background.lighter().cgColor
        scrollContainerView.layer.shadowColor = colors.background.darker().cgColor
    }
    
    private func fetchBeerDetails(){
        untappdMachine.beerDetails(
            beerID: self.beer!.id,
            onSuccess: {json in
                self.spinner.stopAnimating()
                
                let beerData = json["response"]["beer"]
                
                self.beer!.brewery = beerData["brewery"]["brewery_name"].stringValue
                self.beer!.drunk = beerData["auth_rating"].intValue > 0
                self.beer!.style = beerData["beer_style"].stringValue
                self.beer!.abv = beerData["beer_abv"].floatValue
                self.beer!.ibu = beerData["beer_ibu"].intValue
                self.beer!.beerDescription = beerData["beer_description"].stringValue
                
                if(!beerData["beer_label_hd"].stringValue.isEmpty){
                    Alamofire.request(beerData["beer_label_hd"].stringValue).responseImage { response in
                        self.beer!.image = response.result.value!
                        self.labelImage.image = self.beer!.image
                    }
                }
                
                self.updateBeerView()
            },
            onError: {error in
                self.spinner.stopAnimating()
            }
        )
    }

    private func updateBeerView(){
        beerStyleLabel.text = beer!.style
        abvLabel.text = String(beer!.abv!)
        ibuLabel.text = String(beer!.ibu!)
        beerDescriptionLabel.text = beer!.beerDescription
    }
    
}
