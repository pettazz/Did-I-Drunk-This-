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
                               action: { [weak self] completion in
                                   self?.login(presentingViewController, completion)
                               }
        )
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

        _ = self.oauthswift.authorize(
            withCallbackURL: URL(string: "dididrunkthis://oauth-callback/untappd")!,
            scope: "",
            state: "DIDIDRUNKTHIS",
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
    
    private func extractRateLimitRemaining(from response: DataResponse<JSON>) -> Int?{
        let rateLimitRemaining: Int?
        
        if let rateLimitHeaderValue = response.response?.allHeaderFields["x-ratelimit-remaining"] as? String {
            rateLimitRemaining = Int(rateLimitHeaderValue)
        }else{
            rateLimitRemaining = nil
        }
        
        os_log("Rate limit remaining: %@", type: .debug, String(describing: rateLimitRemaining))
        
        return rateLimitRemaining
    }

    // MARK: rest call internals
    private func get(
        endpointName: String,
        withParams: String...,
        onSuccess: @escaping (_ responseValue: JSON, _ rateLimitRemaining: Int?) -> Void,
        onError: @escaping (_ error: Error, _ rateLimitRemaining: Int?, _ errorTitle: String, _ errorMessage: String) -> Void){

        self.ensureTokenExists(onboardingViewController: nil)

        var preparedParams = [String]()
        for(param):(String) in withParams{
            preparedParams.append(param.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
        }

        //TODO: this is pretty dumb, i assume alamofire would make this much easier
        var url = String(format: K.Untappd.Endpoint[endpointName]!, arguments: preparedParams)
        if(url.range(of: "?") != nil){
            url += "&access_token=\(self.token)"
        }else{
            url += "?access_token=\(self.token)"
        }

        os_log("GET: %@", type: .debug, String(url))

        Alamofire.request(url).validate(statusCode: 200..<300).responseSwiftyJSON { response in
            let rateLimitRemaining = self.extractRateLimitRemaining(from: response)
            switch response.result{
                case .success:
                    onSuccess(response.value!, rateLimitRemaining)
                case .failure(let error):
                    let errorDetails = self.getFriendlyErrorDetails(afError: error, response: response)
                    onError(error, rateLimitRemaining, errorDetails.title, errorDetails.message)
            }
        }
    }
    
    private func post(
        endpointName: String,
        withParams: Parameters,
        onSuccess: @escaping (_ responseValue: JSON, _ rateLimitRemaining: Int?) -> Void,
        onError: @escaping (_ error: Error, _ rateLimitRemaining: Int?, _ errorTitle: String, _ errorMessage: String) -> Void){
        
        self.ensureTokenExists(onboardingViewController: nil)

        var url = K.Untappd.Endpoint[endpointName]!
        if(url.range(of: "?") != nil){
            url += "&access_token=\(self.token)"
        }else{
            url += "?access_token=\(self.token)"
        }
        
        os_log("POST: %@", type: .debug, String(url))
        os_log("with params: %@", type: .debug, String(describing: withParams))
        
        Alamofire.request(url, method: .post, parameters: withParams).validate(statusCode: 200..<300).responseSwiftyJSON { response in
            let rateLimitRemaining = self.extractRateLimitRemaining(from: response)
            switch response.result{
            case .success:
                onSuccess(response.value!, rateLimitRemaining)
            case .failure(let error):
                let errorDetails = self.getFriendlyErrorDetails(afError: error, response: response)
                onError(error, rateLimitRemaining, errorDetails.title, errorDetails.message)
            }
        }
    }

    // MARK: error handling
    private func getFriendlyErrorDetails(afError: Error, response: DataResponse<JSON>) -> (title: String, message: String){
        os_log("Response error: %@", type: .error, afError.localizedDescription)

        let titles = [
            "Aw, Dang",
            "Aw, Beans",
            "Oh No",
            "Aw, Jeez",
            "Aw, Farts",
            "Welp",
            "Uh Oh",
            "Sorry"
        ]

        var errorTitle = titles.randomElement() ?? titles[0], errorMessage = "Something went wrong, try again!"

        if let err = afError as? URLError {
            // network errors
            switch(err.code){
                case .notConnectedToInternet, .networkConnectionLost:
                    errorMessage = "You're not connected to the internet! Get online and try again."
                case .timedOut:
                    errorMessage = "We couldn't reach Untappd, you may not be connected to the internet! Try again later."
                default:
                    errorMessage = "Untappd isn't responding! Try again in a bit."
            }
        }else{
            // responses that were bad in some way
            if let body = response.data {
                let errorBody = JSON(body)
                let untappdErrorType = errorBody["meta"]["error_type"].string
                let untappdErrorDetail = errorBody["meta"]["error_detail"].string
                let untappdErrorFriendly = errorBody["meta"]["developer_friendly"].string

                os_log("Untappd Error Type: %@", type: .error, untappdErrorType ?? "none")
                os_log("Untappd Error Details: %@", type: .error, untappdErrorDetail ?? "none")
                os_log("Untappd Error Friendly: %@", type: .error, untappdErrorFriendly ?? "none")

                if let friendly = untappdErrorFriendly.nilIfEmpty {
                    errorMessage = friendly
                }else{
                    switch(untappdErrorType){
                        case "invalid_limit":
                            errorMessage = "Whoa, whoa, slow down! You've reached your limit for requests to Untappd for the hour! Try again in a bit."
                        case "DB_Error":
                            errorMessage = "Untappd is currently down! Try again later."
                        case "invalid_auth":
                            errorMessage = "Your login has expired, go back to the search page to log in again."
                        default:
                            errorMessage = "We couldn't talk to Untappd for some reason! Try again in a bit."
                    }
                }
            }
        }

        return (title: errorTitle, message: errorMessage)
    }

    // MARK: public methods
    // MARK: specific endpoints
    public func beerSearch(
        searchText: String,
        onSuccess: @escaping (_ responseValue: JSON, _ rateLimitRemaining: Int?) -> Void,
        onError: @escaping (_ error: Error, _ rateLimitRemaining: Int?, _ errorTitle: String, _ errorMessage: String) -> Void){

        self.get(
            endpointName: "BeerSearch",
            withParams: searchText,
            onSuccess: onSuccess,
            onError: onError)
    }

    public func beerDetails(
        beerID: Int,
        onSuccess: @escaping (_ responseValue: JSON, _ rateLimitRemaining: Int?) -> Void,
        onError: @escaping (_ error: Error, _ rateLimitRemaining: Int?, _ errorTitle: String, _ errorMessage: String) -> Void){

        self.get(
            endpointName: "BeerDetails",
            withParams: String(beerID),
            onSuccess: onSuccess,
            onError: onError)
    }
    
    public func checkIn(
        beerID: Int,
        rating: Double,
        onSuccess: @escaping (_ responseValue: JSON, _ rateLimitRemaining: Int?) -> Void,
        onError: @escaping (_ error: Error, _ rateLimitRemaining: Int?, _ errorTitle: String, _ errorMessage: String) -> Void){

        let myTZ = TimeZone.autoupdatingCurrent
        let gmtOffset : Int = (myTZ.secondsFromGMT() / 60 / 60)
        let tzAbbr : String = myTZ.abbreviation() ?? ""
        
        let params : Parameters = [
            "bid": beerID,
            "gmt_offset": gmtOffset,
            "timezone": tzAbbr,
            "rating": rating
        ]
        
        self.post(
            endpointName: "CheckIn",
            withParams: params,
            onSuccess: onSuccess,
            onError: onError)
    }

}

enum TokenError: Error {
    case noTokenStoredInKeychain
}
