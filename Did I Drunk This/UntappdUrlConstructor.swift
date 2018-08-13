//
//  UntappdUrlConstructor.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/12/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit
import os.log

class UntappdUrlConstructor: NSObject {
    var token = String()
    
    func setToken(token: String){
        self.token = token
    }
    
    func get(endpointName: String, params: String...) -> String{
        guard self.token != "" else {
            //TODO: handle this better
            fatalError("Can't call an endpoint before token has been set")
        }
        
        var preparedParams = [String]()
        for(param):(String) in params{
            preparedParams.append(param.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
        }
        
        var result = String(format: K.Untappd.Endpoint[endpointName]!, arguments: preparedParams)
        result += "&access_token=\(self.token)"
        return  result
    }
}
