//
//  Constants.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/12/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import Foundation

struct K{
    struct Untappd{
        static let BaseUrl = "https://api.untappd.com/v4/"
        
        static let ClientID = "no"
        static let ClientSecret = "lol"
        
        static let Endpoint: [String:String] = [
            "Authenticate": "https://untappd.com/oauth/authenticate/",
            
            "BeerSearch": "\(K.Untappd.BaseUrl)search/beer?q=%@",
            "BeerDetails": "\(K.Untappd.BaseUrl)beer/info/%@"
        ]
    }
}
