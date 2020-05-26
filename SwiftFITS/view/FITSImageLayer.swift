//
//  FITSImageLayer.swift
//  SwiftFITS
//
//  Created by Don Willems on 25/05/2020.
//  Copyright © 2020 lapsedpacifist. All rights reserved.
//

import Cocoa

public class FITSImageLayer: CelestialViewLayer {
    
    public var FITSFile : FITS
    
    public init(with data: FITS) {
        self.FITSFile = data
    }
    
    public func draw(_ dirtyRect: NSRect, in view: CelestialView) {
        print("Drawing FITS layer")
        let data = self.FITSFile.primaryDataArray
        let image = data?.image
        let imageRect = NSRect(x: 0, y: 0, width: data!.lengthOfDataAxis[0], height: data!.lengthOfDataAxis[1])
        let wby = view.frame.width / view.frame.height
        let iwby = imageRect.size.width / imageRect.size.height
        var targetRect = NSMakeRect(0, 0, 0, 0)
        if iwby > wby {
            targetRect.origin.x = 0.0
            targetRect.size.width = view.frame.width
            targetRect.size.height = view.frame.width / iwby
            targetRect.origin.y = (view.frame.height - targetRect.size.height) / 2.0
        } else {
            targetRect.origin.y = 0.0
            targetRect.size.width = view.frame.height * iwby
            targetRect.size.height = view.frame.height
            targetRect.origin.x = (view.frame.width - targetRect.size.width) / 2.0
        }
        let nsimage = NSImage(cgImage: image!, size: NSMakeSize(CGFloat((data!.lengthOfDataAxis[0])), CGFloat(data!.lengthOfDataAxis[1])))
        nsimage.draw(in: targetRect)
    }
}
