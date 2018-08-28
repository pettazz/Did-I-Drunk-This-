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
    
    @IBOutlet weak var labelImage: UIImageView!
    
    @IBOutlet weak var scrollContainerView: UIScrollView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var meRatingTitleLabel: UILabel!
    @IBOutlet weak var everyoneRatingTitleLabel: UILabel!
    @IBOutlet weak var abvTitleLabel: UILabel!
    @IBOutlet weak var ibuTitleLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var breweryNameLabel: UILabel!
    @IBOutlet weak var beerStyleLabel: UILabel!
    @IBOutlet weak var abvLabel: UILabel!
    @IBOutlet weak var ibuLabel: UILabel!
    @IBOutlet weak var beerDescriptionLabel: UILabel!
    
    @IBOutlet weak var meRatingDisplay: CosmosView!
    @IBOutlet weak var everyoneRatingDisplay: CosmosView!
    
    @IBAction func unwindSegueToBeerSearch(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToBeerSearch", sender: self)
    }
    
    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchBeerDetails()
        
        navigationItem.largeTitleDisplayMode = .never
        
        scrollContainerView.layer.borderWidth = 1
        scrollContainerView.layer.shadowOpacity = 0.9
        scrollContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        scrollContainerView.layer.shadowRadius = 2
        scrollContainerView.layer.masksToBounds = false
        
        nameLabel.text = beer!.name
        breweryNameLabel.text = beer!.brewery
        meRatingDisplay.rating = beer!.meRating
        labelImage.image = beer!.image
        labelImage.layer.cornerRadius = 3
        labelImage.layer.shadowOpacity = 0.9
        labelImage.layer.shadowOffset = CGSize(width: 0, height: 0)
        labelImage.layer.shadowRadius = 3
        labelImage.layer.masksToBounds = false
        
        self.colors = labelImage.image!.getColors(quality: .low)
        self.updateColors(false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = self.colors.background.isLight()! ? .default : .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - Private Methods
    private func updateColors(_ animated: Bool){
        if(animated){
            UIView.animate(withDuration: 0.5, animations: self.setColors)
        }else{
            self.setColors()
        }
    }
    
    private func setColors() -> Void{
        self.view.backgroundColor = self.colors.primary
        self.navigationController!.navigationBar.barTintColor = self.colors.background
        
        self.meRatingTitleLabel.textColor = self.colors.background
        self.everyoneRatingTitleLabel.textColor = self.colors.background
        
        self.ibuTitleLabel.textColor = self.colors.primary
        self.abvTitleLabel.textColor = self.colors.primary
        
        self.nameLabel.textColor = self.colors.primary
        self.breweryNameLabel.textColor = self.colors.detail
        self.beerStyleLabel.textColor = self.colors.secondary
        self.abvLabel.textColor = self.colors.secondary
        self.ibuLabel.textColor = self.colors.secondary
        self.beerDescriptionLabel.textColor = self.colors.secondary
        
        self.scrollContainerView.backgroundColor = self.colors.background
        self.scrollContainerView.layer.borderColor = self.colors.background.lighter().cgColor
        self.scrollContainerView.layer.shadowColor = self.colors.background.darker().cgColor
        
        self.labelImage.layer.shadowColor = self.colors.background.darker().cgColor
    }
    
    private func fetchBeerDetails(){
        untappdMachine.beerDetails(
            beerID: self.beer!.id,
            onSuccess: {json in
                self.spinner.stopAnimating()
                
                let beerData = json["response"]["beer"]
                
                self.beer!.everyoneRating = beerData["rating_score"].doubleValue
                self.beer!.brewery = beerData["brewery"]["brewery_name"].stringValue
                self.beer!.drunk = beerData["auth_rating"].intValue > 0
                self.beer!.style = beerData["beer_style"].stringValue
                self.beer!.abv = beerData["beer_abv"].doubleValue
                self.beer!.ibu = beerData["beer_ibu"].intValue
                self.beer!.beerDescription = beerData["beer_description"].stringValue
                
                if(!beerData["beer_label_hd"].stringValue.isEmpty){
                    Alamofire.request(beerData["beer_label_hd"].stringValue).responseImage { response in
                        self.beer!.image = response.result.value!
                        self.labelImage.image = self.beer!.image
                        self.colors = self.labelImage.image!.getColors(quality: .low)
                        self.updateColors(true)
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
        everyoneRatingDisplay.rating = beer!.everyoneRating!
        beerStyleLabel.text = beer!.style
        abvLabel.text = String(beer!.abv!)
        ibuLabel.text = String(beer!.ibu!)
        beerDescriptionLabel.text = beer!.beerDescription
    }
    
}
