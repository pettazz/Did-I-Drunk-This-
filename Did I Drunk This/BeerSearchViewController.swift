//
//  ViewController.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/5/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

import Alamofire
import Alamofire_SwiftyJSON
import KeychainAccess
import OAuthSwift
import OnboardKit
import SwiftyJSON

class BeerSearchViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Properties
    @IBOutlet var tableView: UITableView!
    
    var beers = [Beer]()
    var filteredBeers = [Beer]()
    
    let keychain = Keychain(service: "com.pettazz.did-i-drunk-this")
    let searchController = UISearchController(searchResultsController: nil)
    let urlMachine = UntappdUrlConstructor()
    
    var oauthswift = OAuth2Swift(
        consumerKey:    K.Untappd.ClientID,
        consumerSecret: K.Untappd.ClientSecret,
        authorizeUrl:   K.Untappd.Endpoint["Authenticate"]!,
        responseType:   "token"
    )
    
    lazy var debouncedFilterContentForSearchText: (String) -> () = debounce(delay: 1, action: self.filterContentForSearchText)
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Beers"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // if this is the first time opening the app, trigger the onboard/login
        let token = getUntappdToken()
        if(token != ""){
            urlMachine.setToken(token: token)
        }
    }
    
    // MARK: - Private methods
    
    private func getUntappdToken() -> String {
        // MARK: delete me: force reset token
//        keychain[string: "untappd-token"] = nil
        
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
        self.oauthswift.authorizeURLHandler = SafariURLHandler(
            viewController: self.presentedViewController!,
            oauthSwift: self.oauthswift)
        
        let _ = self.oauthswift.authorize(
            withCallbackURL: URL(string: "dididrunkthis://oauth-callback/untappd")!,
            scope: "",
            state:"DIDIDRUNKTHIS",
            success: { credential, response, parameters in
                self.keychain[string: "untappd-token"] = credential.oauthToken
                self.urlMachine.setToken(token: credential.oauthToken)
                self.presentedViewController!.dismiss(animated: true)
            },
                failure: { error in
                    fatalError(error.localizedDescription)
            }
        )
    }
    
    func searchBarIsEmptyOrTooSmall() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true ||
               searchController.searchBar.text?.count ?? 0 < 3
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmptyOrTooSmall()
    }
    
    func filterContentForSearchText(_ searchText: String) {
        Alamofire.request(urlMachine.get(endpointName: "BeerSearch", params: searchText)).responseSwiftyJSON { response in
            //os_log("Request: %@", type: .debug, String(describing: response.request))
            //os_log("Response: %@", type: .debug, String(describing: response))
            
            if let json = response.value {
                let responseBeers = json["response"]["beers"]["items"]
                os_log("got %u beers", type: .debug, responseBeers.count)
                for(_, subJson):(String, JSON) in responseBeers{
                    let newBeer = Beer(
                        name: subJson["beer"]["beer_name"].stringValue,
                        brewery: subJson["brewery"]["brewery_name"].stringValue,
                        image: nil,
                        drunk: subJson["have_had"].boolValue
                    )
                    self.filteredBeers.append(newBeer)
                    //os_log("added %@", type: .debug, newBeer.name)
                }
                
                self.tableView.reloadData()
            }
        }
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
    
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        self.filteredBeers = [Beer]()
        //TODO: show a loading indicator somehow
        self.tableView.reloadData()
        
        if(searchBarIsEmptyOrTooSmall()){
            tableView.reloadData()
            return
        }
        
        self.debouncedFilterContentForSearchText(self.searchController.searchBar.text!)
    }
}
