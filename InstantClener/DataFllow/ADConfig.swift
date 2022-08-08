//
//  ADConfig.swift
//  InstantClener
//
//  Created by yangjian on 2022/8/8.
//

import Foundation

struct ADConfig: Codable {
    var installOnlyTouch: Bool?
    var showTimes: Int?
    var clickTimes: Int?
    var ads: [ADModels?]?
    
    func arrayWith(_ postion: ADPosition) -> [ADModel] {
        guard let ads = ads else {
            return []
        }
        
        guard let models = ads.filter({$0?.key == postion.rawValue}).first as? ADModels, let array = models.value   else {
            return []
        }
        
        return array.sorted(by: {$0.theAdPriority > $1.theAdPriority})
    }
    struct ADModels: Codable {
        var key: String
        var value: [ADModel]?
    }
}
