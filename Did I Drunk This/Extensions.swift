//
//  Extensions.swift
//  Did I Drunk This
//
//  Created by Nick Pettazzoni on 8/19/18.
//  Copyright © 2018 Nick Pettazzoni. All rights reserved.
//

import UIKit

// a whole pile of various helper extensions

extension UIImageView{
    func addGradientLayer(colors:[UIColor]){
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.frame.width, height: self.frame.height)
        gradient.colors = colors.map{$0.cgColor}
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        self.layer.addSublayer(gradient)
    }
}
