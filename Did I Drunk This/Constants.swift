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
        
        static let ClientID = "86F7C2065CB32B9A1B15DE6EBFFAF0458685822E"
        static let ClientSecret = "772C0F4DC8B119C8E0F39B1C70858B7E2FA24B30"
        
        struct Endpoint{
            static let authenticate = "https://untappd.com/oauth/authenticate/"
        }
    }
}
