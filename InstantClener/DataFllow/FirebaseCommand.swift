//
//  FirebaseCommand.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/5.
//

import Foundation
import Firebase

struct FirebasePropertyCommand: Command {
    let property: AppState.Firebase.FirebaseProperty
    let value: String?
    init(_ property: AppState.Firebase.FirebaseProperty, _ value: String?) {
        self.property = property
        self.value = value
    }
    func execute(in store: Store) {
        var value = value
        
        if UserDefaults.standard.string(forKey: property.rawValue) == nil {
            value = "1"
            UserDefaults.standard.set("1", forKey: property.rawValue)
            UserDefaults.standard.set(Date(), forKey: "firebase.is.new.data")
        } else {
            let string = UserDefaults.standard.string(forKey: property.rawValue)
            let date = UserDefaults.standard.value(forKey: "firebase.is.new.data") as! Date
            if string == "1", Date().timeIntervalSince1970 - date.timeIntervalSince1970 > 12 * 60 * 60 {
                UserDefaults.standard.set("0", forKey: property.rawValue)
            }
            value = UserDefaults.standard.string(forKey: property.rawValue)
        }
#if DEBUG
#else
        Analytics.setUserProperty(value, forName: name.rawValue)
#endif
        debugPrint("[ANA] [Property] \(property.rawValue) \(value ?? "")")
    }
}

struct FirebaseEvnetCommand: Command {
    let event: AppState.Firebase.FirebaseEvent
    let params: [String:String]?
    init(_ event: AppState.Firebase.FirebaseEvent, _ params: [String:String]?) {
        self.event = event
        self.params = params
    }
    func execute(in store: Store) {
        if event.first {
            if UserDefaults.standard.bool(forKey: event.rawValue) == true {
                return
            } else {
                UserDefaults.standard.set(true, forKey: event.rawValue)
            }
        }
        
        #if DEBUG
        #else
        Analytics.logEvent(name.rawValue, parameters: params)
        #endif
        
        debugPrint("[ANA] [Event] \(event.rawValue) \(params ?? [:])")
    }
}
