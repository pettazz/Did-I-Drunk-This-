//
//  UntappdService.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/12/18.
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

class UntappdService: NSObject {
    private var token = String()

    private let keychain = Keychain(service: "com.pettazz.did-i-drunk-this")
    private var oauthswift = OAuth2Swift(
        consumerKey:    K.Untappd.ClientID,
        consumerSecret: K.Untappd.ClientSecret,
        authorizeUrl:   K.Untappd.Endpoint["Authenticate"]!,
        responseType:   "token"
    )
    
    // MARK: - public methods
    func ensureTokenExists(onboardingViewController: UIViewController?){
        if(self.token.isEmpty){
            do{
                try self.token = self.getStoredToken()
            }catch _ as TokenError{
                if(onboardingViewController != nil){
                    self.attemptOnboarding(presentingViewController: onboardingViewController!)
                }else{
                    fatalError("No token stored, not called from viewController context")
                }
            }catch{
                fatalError("Unhandled Error getting token from Keychain")
            }
        }
    }
    
    // MARK: - private methods
    // MARK: token/login handling
    private func getStoredToken() throws -> String{
        // MARK: delete me: force reset token
//        keychain[string: "untappd-token"] = nil
        if let storedToken = try? keychain.get("untappd-token"){
            if(storedToken == nil || storedToken == ""){
                throw TokenError.noTokenStoredInKeychain
            }else{
                return storedToken!
            }
        }else{
            fatalError("Unable to access untappd-token in Keychain")
        }
    }
    
    private func storeToken(token: String){
        self.keychain[string: "untappd-token"] = token
    }
    
    private func attemptOnboarding(presentingViewController: UIViewController){
        let page = OnboardPage(title: "You gotta log in tho",
                               imageName: "onboard",
                               description: "Promise not to steal your Untappd identity.",
                               advanceButtonTitle: "Cancel",
                               actionButtonTitle: "Log in with Untappd",
                               action: {
                                [weak self] completion in
                                self?.login(presentingViewController, completion)
        })
        let appearance = OnboardViewController.AppearanceConfiguration(tintColor: .white,
                                                                       textColor: .black,
                                                                       backgroundColor: .orange,
                                                                       titleFont: UIFont.boldSystemFont(ofSize: 24),
                                                                       textFont: UIFont.boldSystemFont(ofSize: 18))
        let onboardingViewController = OnboardViewController(pageItems: [page], appearanceConfiguration: appearance)
        onboardingViewController.presentFrom(presentingViewController, animated: true)
    }
    
    private func login(_ presentingViewController: UIViewController, _ completion: @escaping (_ success: Bool, _ error: Error?) -> Void){
        self.oauthswift.authorizeURLHandler = SafariURLHandler(
            viewController: presentingViewController.presentedViewController!,
            oauthSwift: self.oauthswift)
        
        let _ = self.oauthswift.authorize(
            withCallbackURL: URL(string: "dididrunkthis://oauth-callback/untappd")!,
            scope: "",
            state:"DIDIDRUNKTHIS",
            success: { credential, response, parameters in
                self.storeToken(token: credential.oauthToken)
                self.token = credential.oauthToken
                presentingViewController.presentedViewController!.dismiss(animated: true)
        },
            failure: { error in
                fatalError(error.localizedDescription)
            }
        )
    }
    
    //MARK: rest call internals
    private func get(
        endpointName: String,
        withParams: String...,
        onSuccess: @escaping (_ responseValue: JSON) -> Void,
        onError: @escaping (_ error: Error) -> Void){
        
        self.ensureTokenExists(onboardingViewController: nil)
        
        var preparedParams = [String]()
        for(param):(String) in withParams{
            preparedParams.append(param.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
        }
        
        //TODO: this is pretty dumb, i assume alamofire would make this much easier
        var url = String(format: K.Untappd.Endpoint[endpointName]!, arguments: preparedParams)
        if(url.range(of:"?") != nil){
            url += "&access_token=\(self.token)"
        }else{
            url += "?access_token=\(self.token)"
        }
        
        Alamofire.request(url)
                 .validate(statusCode: 200..<300)
                 .responseSwiftyJSON { response in
                    
            os_log("Request: %@", type: .debug , String(describing: response.request))
//            os_log("Response: %@", type: .debug, String(describing: response))
            
            switch response.result{
                case .success:
                    onSuccess(response.value!)
                case .failure(let error):
                    os_log("Response error: %@", type: .error, error.localizedDescription)
                    onError(error)
            }
        }
    }
    
    //MARK: specific endpoints
    public func beerSearch(
        searchText: String,
        onSuccess: @escaping (_ responseValue: JSON) -> Void,
        onError: @escaping (_ error: Error) -> Void){
        
        self.get(
            endpointName: "BeerSearch",
            withParams: searchText,
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func beerDetails(
        beerID: Int,
        onSuccess: @escaping (_ responseValue: JSON) -> Void,
        onError: @escaping (_ error: Error) -> Void){
        
        self.get(
            endpointName: "BeerDetails",
            withParams: String(beerID),
            onSuccess: onSuccess,
            onError: onError)
    }
        
}

enum TokenError: Error {
    case noTokenStoredInKeychain
}
