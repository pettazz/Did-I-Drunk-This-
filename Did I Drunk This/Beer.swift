//
//  Beer.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/9/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import Foundation
import UIKit

class Beer: NSObject{
    
    //MARK: Properties
    var id: Int
    var name: String
    var brewery: String
    var image: String
    var drunk: Bool = false
    var meRating: Float
    var everyoneRating: Float? = nil
    var abv: Float? = nil
    var ibu: Int? = nil
    var style: String? = nil
    var beerDescription: String? = nil
    var onWishList: Bool? = nil

    //MARK: Initialization
    init(id: Int,
         name: String,
         brewery: String,
         image: String,
         drunk: Bool,
         meRating: Float) {
        self.id = id
        self.name = name
        self.brewery = brewery
        self.image = image
        self.drunk = drunk
        self.meRating = meRating
    }
    
    
    
}
