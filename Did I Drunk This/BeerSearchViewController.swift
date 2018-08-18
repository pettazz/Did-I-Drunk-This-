//
//  ViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/5/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

import AlamofireImage
import SwiftyJSON

class BeerSearchViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Properties
    @IBOutlet var tableView: UITableView!
    
    var foundBeers = [Beer]()
    
    let searchController = UISearchController(searchResultsController: nil)
    let untappdMachine = UntappdService()
    
    lazy var debouncedPerformSearch: (String) -> () = debounce(delay: 1, action: self.performSearch)
    
    //MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Beer or Brewery Name"
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.barStyle = .black
        tableView.tableHeaderView = searchController.searchBar
        //tableView.backgroundColor = UIColor(red:0.00, green:0.30, blue:0.47, alpha:1.0)
        //tableView.tableHeaderView?.backgroundColor = UIColor.darkGray
        definesPresentationContext = true
        
        // if this is the first time opening the app, trigger the onboard/login
        untappdMachine.ensureTokenExists(onboardingViewController: self)
    }
    
    // MARK: - Private methods
    func searchContentIsEmptyOrTooSmall() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true ||
               searchController.searchBar.text?.count ?? 0 < 3
    }
    
    func performSearch(_ searchText: String) {
        // loading spinner
        if(searchController.isActive){
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            indicator.tag = 101
            indicator.center = self.tableView.convert(self.tableView.center, from:self.tableView.superview)
        
            self.tableView.addSubview(indicator)
            indicator.startAnimating()
        }
        
        untappdMachine.beerSearch(
            searchText: searchText,
            onSuccess: {json in
                var newBeerList = [Beer]()
                let responseBeers = json["response"]["beers"]["items"]
                
                os_log("got %u beers", type: .debug, responseBeers.count)
                for(_, subJson):(String, JSON) in responseBeers{
                    let newBeer = Beer(
                        id: subJson["beer"]["bid"].intValue,
                        name: subJson["beer"]["beer_name"].stringValue,
                        brewery: subJson["brewery"]["brewery_name"].stringValue,
                        image: subJson["beer"]["beer_label"].stringValue,
                        drunk: subJson["have_had"].boolValue
                    )
                    newBeerList.append(newBeer)
                }
                self.foundBeers = newBeerList
                
                //TODO: bleh this is terrible
                self.tableView.viewWithTag(101)?.removeFromSuperview()
                
                self.tableView.reloadData()
            },
            onError: {error in
                //TODO: better error handling
                self.tableView.viewWithTag(101)?.removeFromSuperview()
            }
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foundBeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "beerCell", for: indexPath) as! BeerTableViewCell
        let beer: Beer
        
        beer = foundBeers[indexPath.row]
        
        cell.nameLabel!.text = beer.name
        cell.breweryLabel!.text = beer.brewery
        cell.labelImage.af_setImage(
            withURL: URL(string: beer.image)!,
            placeholderImage: UIImage(named: "beerPlaceholder")!)
        cell.drunkLabel.isHidden = !beer.drunk
        //cell.drunkLabel.text = "✅"
        
        return cell
    }
    
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        if(searchContentIsEmptyOrTooSmall()){
            self.foundBeers = [Beer]()
            self.tableView.reloadData()
            return
        }
        
        self.debouncedPerformSearch(searchController.searchBar.text!)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let beerDetailController = segue.destination as? BeerDetailViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        guard let selectedBeerCell = sender as? BeerTableViewCell else {
            fatalError("Unexpected sender: \(String(describing: sender))")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedBeerCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedBeer = foundBeers[indexPath.row]
        beerDetailController.beer = selectedBeer
    }
}
