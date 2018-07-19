//
//  Utils.swift
//  Vesion 1.1
//
//  Created by Samuel Kobelkowsky on 5/24/18.
//  Copyright © 2018 Kobelsoft. All rights reserved.
//

import UIKit

// Shows an alert with an OK button and when the user clicks on the button, execute the "completion" function given
class Alert {
    static func show(_ viewController: UIViewController,title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}
