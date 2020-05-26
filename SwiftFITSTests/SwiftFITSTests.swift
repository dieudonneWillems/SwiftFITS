//
//  SwiftFITSTests.swift
//  SwiftFITSTests
//
//  Created by Don Willems on 20/01/2020.
//  Copyright © 2020 lapsedpacifist. All rights reserved.
//

import XCTest
@testable import SwiftFITS

class SwiftFITSTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let url = Bundle(for: SwiftFITSTests.self).url(forResource: "Sadr_Light_052", withExtension: "fits")
        do {
            print("URL: \(url) exists.")
            var fits = try FITS(atURL: url!)
            let header = fits.primaryHeader
            for record in header.keywordRecords {
                print(record)
            }
            let data = fits.primaryDataArray
            let image = data?.image
            print("data loaded: ")
        } catch {
            print("URL: \(url) does not exist.")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
