//
//  Session.swift
//  Tripfinger
//
//  Created by Preben Ludviksen on 08/10/15.
//  Copyright (c) 2015 Preben Ludviksen. All rights reserved.
//

import Foundation
 class Session {
    
    init() {}
    
    var currentRegion: Region?
    var currentAttractions = [Attraction]()
    
    func loadBrusselsAsCurrentRegionIfEmpty(handler: () -> ()) {
        if currentRegion == nil {
            ContentService.getRegions() {
                regions in
                
                self.loadRegionWithID(regions[0].id, handler: handler)
            }
        }
        else {
            handler()
        }
    }
    
    func loadRegionWithID(regionId: Int, handler: () -> ()) {
        
        ContentService.getRegionWithId(regionId) {
            region in
            
            self.currentRegion = region
            handler()
        }
    }

    
    func loadAttractions(handler: () -> ()) {
        ContentService.getAttractionsForRegion(self.currentRegion!) {
            attractions in
            
            self.currentAttractions = attractions
            handler()
        }

    }
}