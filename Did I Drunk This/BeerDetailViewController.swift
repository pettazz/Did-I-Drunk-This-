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

    // MARK: - Properties
    let untappdMachine = UntappdService()
    var colors = UIImageColors(background: .darkGray, primary: .white, secondary: .gray, detail: .orange)

    var beer: Beer?
    var beerLabelImage: UIImage?

    @IBOutlet weak var labelImage: UIImageView!

    @IBOutlet weak var scrollContainerView: UIScrollView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var backgroundLayerView: UIView!

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

    @IBOutlet weak var untappdLinkButton: UIButton!
    @IBOutlet weak var checkinButton: UIButton!

    @IBOutlet weak var meRatingDisplay: CosmosView!
    @IBOutlet weak var everyoneRatingDisplay: CosmosView!

    @IBAction func unwindSegueToBeerSearch(_ sender: Any) {
        performSegue(withIdentifier: "unwindSegueToBeerSearch", sender: self)
    }

    @IBAction func linkToUntappd() {
        self.openUntappdURL()
    }

    @IBAction func checkin() {
        
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        backgroundLayerView.layer.borderWidth = 1

        nameLabel.text = beer!.name
        breweryNameLabel.text = beer!.brewery
        meRatingDisplay.rating = beer!.meRating
        labelImage.image = beer!.image
        labelImage.layer.cornerRadius = 3
        labelImage.layer.shadowOpacity = 0.9
        labelImage.layer.shadowOffset = CGSize(width: 0, height: 0)
        labelImage.layer.shadowRadius = 3
        labelImage.layer.masksToBounds = false

        colors = labelImage.image!.getColors(quality: .low)
        updateColors(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let isBackgroundLight = self.colors.background.isLight()!

        UIApplication.shared.statusBarStyle = isBackgroundLight ? .default : .lightContent
        spinner.style = isBackgroundLight ? .gray : .white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fetchBeerDetails()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.updateColors(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Private Methods
    private func updateColors(_ animated: Bool){
        if(animated){
            UIView.animate(withDuration: 0.5, animations: self.setColors)
        }else{
            self.setColors()
        }
    }

    private func setColors(){
        self.backgroundLayerView.backgroundColor = self.colors.primary
        self.backgroundLayerView.layer.borderColor = self.colors.background.lighter().cgColor
        self.backgroundLayerView.addShadow(to: [.bottom], radius: 3.0, fromColor: self.colors.background.darker(), toColor:self.colors.primary)

        self.navigationController!.navigationBar.barTintColor = self.colors.background

        self.meRatingTitleLabel.textColor = self.colors.background
        self.everyoneRatingTitleLabel.textColor = self.colors.background

        self.ibuTitleLabel.textColor = self.colors.primary
        self.abvTitleLabel.textColor = self.colors.primary

        self.untappdLinkButton.setTitleColor(self.colors.detail, for: .normal)

        self.nameLabel.textColor = self.colors.primary
        self.breweryNameLabel.textColor = self.colors.detail
        self.beerStyleLabel.textColor = self.colors.secondary
        self.abvLabel.textColor = self.colors.secondary
        self.ibuLabel.textColor = self.colors.secondary
        self.beerDescriptionLabel.textColor = self.colors.secondary

        self.scrollContainerView.backgroundColor = self.colors.background

        self.labelImage.layer.shadowColor = self.colors.background.darker().cgColor
    }

    private func fetchBeerDetails(){
        untappdMachine.beerDetails(
            beerID: self.beer!.id,
            onSuccess: {json, rateLimitRemaining in
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
                        self.colors = self.labelImage.image!.getColors(quality: .high)

                        self.spinner.stopAnimating()
                        self.updateColors(true)
                        self.updateBeerView()
                    }
                }else{
                    self.spinner.stopAnimating()
                    self.updateColors(true)
                    self.updateBeerView()
                }

            },
            onError: {error, rateLimitRemaining, errorTitle, errorMessage in
                self.spinner.stopAnimating()

                let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .cancel))
                self.present(alert, animated: true, completion: nil)
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

    private func openUntappdURL(){
        if let url = URL(string:"untappd://beer/\(self.beer!.id)"){
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let checkinViewController = segue.destination as? CheckinViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }

        let selectedBeer = self.beer
        checkinViewController.beer = selectedBeer
    }
}
