//
//  ViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/5/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit

import os.log

class BeerSearchViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Properties
    @IBOutlet var tableView: UITableView!
    
    var beers = [
        Beer(name: "Sculpin IPA", brewery: "Ballast Point", image: nil, drunk: true),
        Beer(name: "Sam Adams Boston Lager", brewery: "Boston Beer Co", image: nil, drunk: true)
    ]
    var filteredBeers = [Beer]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Beers"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Private methods
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredBeers = beers.filter({( beer : Beer) -> Bool in
            return beer.name.lowercased().contains(searchText.lowercased()) ||
                beer.brewery.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredBeers.count
        }
        
        return beers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "beerCell", for: indexPath) as! BeerTableViewCell
        let beer: Beer
        
        if isFiltering() {
            beer = filteredBeers[indexPath.row]
        } else {
            beer = beers[indexPath.row]
        }
        
        cell.nameLabel!.text = beer.name
        cell.breweryLabel!.text = beer.brewery
        
        return cell
    }
    
    //MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        print(searchText)
    }
    
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
