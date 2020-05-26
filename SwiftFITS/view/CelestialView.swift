//
//  CelestialView.swift
//  SwiftFITS
//
//  Created by Don Willems on 25/05/2020.
//  Copyright © 2020 lapsedpacifist. All rights reserved.
//

import Cocoa

public class CelestialView: NSView {
    
    public private(set) var layers : [CelestialViewLayer] = [CelestialViewLayer]()
    
    public func add(layer : CelestialViewLayer) {
        layers.append(layer)
        self.needsDisplay = true
    }
    
    public func insert(layer : CelestialViewLayer, at index: Int) {
        layers.insert(layer, at: index)
        self.needsDisplay = true
    }
    
    public func remove(at index : Int) {
        layers.remove(at: index)
        self.needsDisplay = true
    }
    
    public func swap(layerAt index1 : Int, withLayerAt index2 : Int) {
        let tempLayer1 = self.layers[index1]
        let tempLayer2 = self.layers[index2]
        self.remove(at: index1)
        self.remove(at: index2)
        if index1 < index2 {
            self.insert(layer: tempLayer1, at: index2)
            self.insert(layer: tempLayer2, at: index1)
        } else {
            self.insert(layer: tempLayer2, at: index1)
            self.insert(layer: tempLayer1, at: index2)
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        for layer in self.layers {
            layer.draw(dirtyRect, in: self)
        }
    }
    
}
