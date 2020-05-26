//
//  CelestialViewLayer.swift
//  SwiftFITS
//
//  Created by Don Willems on 25/05/2020.
//  Copyright © 2020 lapsedpacifist. All rights reserved.
//

import Cocoa

public protocol CelestialViewLayer {
    
    func draw(_ dirtyRect: NSRect, in view: CelestialView)
}
