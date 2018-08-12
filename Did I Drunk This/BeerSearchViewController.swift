//
//  ViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/5/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

import KeychainAccess
import OnboardKit

class BeerSearchViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Properties
    @IBOutlet var tableView: UITableView!
    
    var beers = [
        Beer(name: "Sculpin IPA", brewery: "Ballast Point", image: nil, drunk: true),
        Beer(name: "Sam Adams Boston Lager", brewery: "Boston Beer Co", image: nil, drunk: true)
    ]
    var filteredBeers = [Beer]()
    
    let keychain = Keychain(service: "com.pettazz.did-i-drunk-this")
    let searchController = UISearchController(searchResultsController: nil)
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Beers"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        _ = getUntappdToken()
    }
    
    // MARK: - Private methods
    
    private func getUntappdToken() -> String {
        var token = String()
        
        if let storedToken = try? keychain.get("untappd-token"){
            if(storedToken == nil){
                attemptOnboarding()
            }else{
                token = storedToken!
            }
        }else{
            fatalError("Unable to retrieve untappd-token from Keychain")
        }
        
        return token
    }
    
    private func attemptOnboarding(){
        let page = OnboardPage(title: "You gotta log in tho",
                               imageName: "onboard",
                               description: "Promise not to steal your Untappd identity.",
                               advanceButtonTitle: "Cancel",
                               actionButtonTitle: "Log in with Untappd",
                               action: {
                                [weak self] completion in
                                self?.loginWithUntappd(completion)
        })
        let appearance = OnboardViewController.AppearanceConfiguration(tintColor: .white,
                                                                       textColor: .black,
                                                                       backgroundColor: .orange,
                                                                       titleFont: UIFont.boldSystemFont(ofSize: 24),
                                                                       textFont: UIFont.boldSystemFont(ofSize: 18))
        let onboardingViewController = OnboardViewController(pageItems: [page], appearanceConfiguration: appearance)
        onboardingViewController.presentFrom(self, animated: true)
    }
    
    private func loginWithUntappd(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        let alert = UIAlertController(title: "Login?",
                                      message: "hello this is definitely a real login for sure",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            completion(true, nil)
            self.presentedViewController?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
            completion(false, nil)
        })
        presentedViewController?.present(alert, animated: true)
    }
    
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
