//
//  AppDelegate.swift
//  FITS Viewer
//
//  Created by Don Willems on 25/05/2020.
//  Copyright © 2020 lapsedpacifist. All rights reserved.
//

import Cocoa
import SwiftFITS

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var celestialView: CelestialView!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let url = URL(fileURLWithPath: "/Users/wonco/Downloads/M13_Light_016.fits")
        do {
            var fits = try FITS(atURL: url)
            let header = fits.primaryHeader
            for record in header.keywordRecords {
                print(record)
            }
            let fitsLayer = FITSImageLayer(with: fits)
            celestialView.add(layer: fitsLayer)
        } catch {
            print("URL: \(url) does not exist: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

