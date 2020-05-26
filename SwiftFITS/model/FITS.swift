//
//  FITS.swift
//  SwiftFITS
//
//  Created by Don Willems on 20/01/2020.
//  Copyright © 2020 lapsedpacifist. All rights reserved.
//

import Foundation

/**
 * Represents data in the Flexible Image Transport System format.
 */
public struct FITS {
    
    private var fileHandle : FileHandle
    private var primaryHeaderBlockIndex : Int? = 0
    private var primaryDataBlockIndex : Int?
    private var firstExtensionBlockIndex : Int?

    
    public var primaryHeader : FITSHeader {
        mutating get {
            if _primaryHeader == nil {
                _primaryHeader = readPrimaryHeader()
            }
            return _primaryHeader!
        }
    }
    
    private var _primaryHeader : FITSHeader?

    
    public var primaryDataArray : FITSData? {
        mutating get {
            if _primaryDataArray == nil {
                _primaryDataArray = readPrimaryDataArray()
            }
            return _primaryDataArray!
        }
    }
    
    private var _primaryDataArray : FITSData?
    
    public init?(atPath path: String) {
        let handle = FileHandle(forReadingAtPath: path)
        if handle == nil {
            return nil
        }
        fileHandle = handle!
    }
    
    public init(atURL url: URL) throws {
        self.fileHandle = try FileHandle(forReadingFrom: url)
    }
    
    private mutating func readPrimaryHeader() -> FITSHeader {
        var block : FITSBlock? = nil
        var index = 0
        var header = FITSHeader()
        self.primaryHeaderBlockIndex = 0
        while block != nil || index == 0 {
            block = readBlock(atIndex: index)
            if block != nil {
                let result = header.addBlock(block: block!)
                if !result {
                    block = nil
                }
            }
            index = index + 1
        }
        self.primaryDataBlockIndex = index - 1
        return header
    }
    
    private mutating func readPrimaryDataArray() -> FITSData? {
        let bitpixs = primaryHeader.records(forKeyword: "BITPIX")
        let byteZeros = primaryHeader.records(forKeyword: "BZERO")
        let naxiss = primaryHeader.records(forKeyword: "NAXIS")
        if bitpixs.count == 1 && naxiss.count >= 1 && bitpixs[0].intValue != nil && naxiss[0].intValue != nil {
            var dataSize = abs(bitpixs[0].intValue!)
            let naxis = naxiss[0].intValue!
            var data = Data()
            for index in 0..<naxis {
                let length = naxiss[index + 1].intValue
                if length != nil {
                    dataSize = dataSize * length!
                    let nblocks = 1 + dataSize / FITSBlock.blockSize
                    for blockIndex in 0..<nblocks {
                        let block = readBlock(atIndex: blockIndex + self.primaryDataBlockIndex!)
                        if block == nil {
                            // TODO: Throw error
                        } else {
                            data.append(block!.data)
                        }
                    }
                } else {
                    // TODO: Throw error
                    return nil
                }
            }
            var byteZero = 0
            if byteZeros.count > 0 {
                byteZero = byteZeros[0].intValue!
            }
            let fitsData = FITSData(bitPix: bitpixs[0].intValue!, byteZero: byteZero, naxis: naxiss, data: data)
            return fitsData
        }
        // TODO: Throw error
        return nil
    }
    
    private func readBlock(atIndex index: Int) -> FITSBlock? {
        let offset = UInt64(index * FITSBlock.blockSize)
        do {
            try self.fileHandle.seek(toOffset: offset)
        } catch {
            return nil
        }
        let data = self.fileHandle.readData(ofLength: FITSBlock.blockSize)
        let block = FITSBlock(forIndex: index, withData: data)
        /* // Print first and last bytes of a block
        if block.data.count > 0 {
            for i in 0...10 {
                let u = UnicodeScalar(block.byte(at: i)!)
                let char = String(u)
                print("[\(index)] start \(i): \(block.byte(at: i)!) = \(char)")
            }
            for i in FITSBlock.blockSize-11...FITSBlock.blockSize-1 {
                let u = UnicodeScalar(block.byte(at: i)!)
                let char = String(u)
                print("[\(index)] end \(i): \(block.byte(at: i)!) = \(char)")
            }
        }
         */
        return block
    }
}

fileprivate struct FITSBlock {
    
    /**
     * Block size in a FITS file is defined to be 2880 bytes.
     */
    fileprivate static let blockSize = 2880
    
    let data : Data
    let index : Int
    
    init(forIndex index: Int, withData data: Data) {
        self.data = data
        self.index = index
    }
    
    func byte(at index: Int) -> UInt8? {
        if index < 0 || index >= data.count {
            return nil
        }
        return data[index]
    }
}

public struct FITSHeader {
    
    private var string = ""
    public var keywordRecords = [KeywordRecord]()
    
    public init() {
    }
    
    public var keywords : [String] {
        get {
            var kws = [String]()
            for record in self.keywordRecords {
                let kw = KeywordRecord.sequenceNumber(forKeyword: record.name)
                if !kws.contains(kw.keyword) {
                    kws.append(kw.keyword)
                }
            }
            return kws
        }
    }
    
    public func records(forKeyword keyword: String) -> [KeywordRecord] {
        let kw = KeywordRecord.sequenceNumber(forKeyword: keyword)
        let number = kw.number
        var records = [KeywordRecord]()
        for record in self.keywordRecords {
            if number == nil {
                if record.name.starts(with: keyword) {
                    records.append(record)
                }
            } else {
                if record.name == keyword {
                    records.append(record)
                }
            }
        }
        return records
    }
    
    /**
     * Adds a block to the header. This method returns a boolean that is `true` when the
     * block was indeed a header block. If the block is a data block it returns `false`.
     * - Parameter block: The block of data to be added to the header.
     * - Returns: `true` when the block is a header block, `false` otherwise.
     */
    fileprivate mutating func addBlock(block: FITSBlock) -> Bool {
        let count = FITSBlock.blockSize - 1
        for index in 0...count {
            let byte = block.byte(at: index)
            if byte == nil || byte! < UInt8(32) || byte! > UInt8(126) {
                return false
            }
            let u = UnicodeScalar(byte!)
            let char = String(u)
            string = string + char
            if string.count == 80 {
                let record = KeywordRecord(withString: string)
                if record != nil {
                    keywordRecords.append(record!)
                }
                string = ""
            }
        }
        return true
    }
    
}

public struct KeywordRecord : CustomStringConvertible{
    
    public let name : String
    public private(set) var stringValue : String?
    public private(set) var boolValue : Bool?
    public private(set) var intValue : Int?
    public private(set) var doubleValue : Double?
    public private(set) var comment : String?
    
    fileprivate init?(withString string: String) {
        let start = string.startIndex
        let nameEnd = string.index(string.startIndex, offsetBy: 8)
        let valueStart = string.index(nameEnd, offsetBy: 2)
        let valueEnd = string.index(valueStart, offsetBy: 60)
        name = String(string[start..<nameEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        if name.count == 0 {
            return nil
        }
        let valueComment = String(string[valueStart..<valueEnd])
        let split = valueComment.split(separator: "/")
        stringValue = String(split[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        if split.count == 2 {
            comment = String(split[1])
        } else {
            comment = nil
        }
        let qindexF = stringValue!.firstIndex(of: "'")
        let qindexL = stringValue!.lastIndex(of: "'")
        if qindexF != nil && qindexL != nil && qindexF! != qindexL! {
            let qstart = stringValue!.index(qindexF!, offsetBy: 1)
            var qend = stringValue!.index(qindexL!, offsetBy: -1)
            var char = String(stringValue![qend])
            while char == " " && qend > qstart { // trim whitespace at end
                qend = stringValue!.index(qend, offsetBy: -1)
                char = String(stringValue![qend])
            }
            if qstart < qend {
                stringValue = String(stringValue![qstart...qend])
            } else {
                stringValue = ""
            }
        } else {
            if stringValue!.count > 0 {
                if stringValue! == "F" {
                    boolValue = false
                } else if stringValue! == "T" {
                    boolValue = true
                } else if let intv = Int(stringValue!) {
                    intValue = intv
                } else if let doublev = Double(stringValue!) {
                   doubleValue = doublev
               }
            }
            stringValue = nil
        }
    }
    
    fileprivate static func sequenceNumber(forKeyword keyword: String) -> (keyword: String, number: Int?) {
        var unnumbered = keyword
        var number : String? = nil
        var suff = unnumbered.suffix(1)
        while suff >= "0" && suff <= "9" {
            if number == nil {
                number = ""
            }
            number = suff + number!
            let first = unnumbered.startIndex
            let last = unnumbered.index(first, offsetBy: unnumbered.count-2)
            unnumbered = String(unnumbered[first...last])
            suff = unnumbered.suffix(1)
        }
        if number != nil {
            return (keyword: unnumbered, number: Int(number!))
        }
        return (keyword: keyword, number: nil)
    }
    
    public var description: String {
        var string = "" + name + " = "
        if stringValue != nil {
            string = string + "'\(stringValue!)'"
        } else if boolValue != nil {
            string = string + "\(boolValue!)"
        } else if intValue != nil {
            string = string + "\(intValue!)"
        } else if doubleValue != nil {
            string = string + "\(doubleValue!)"
        }
        if comment != nil {
            string = string + "\n\t comment: \(comment!)"
        }
        return string
    }
}

public struct FITSData {
    
    fileprivate let data : Data
    public let bitsPerPixel : Int
    public let isFloatingPoint : Bool
    public let numberOfAxes : Int
    public let lengthOfDataAxis : [Int]
    private var multipliers : [Int]
    private let byteZero : Int
    
    fileprivate init?(bitPix: Int, byteZero: Int,  naxis: [KeywordRecord], data: Data) {
        if naxis.count > 0 && naxis[0].intValue != nil{
            let numberOfAxes = naxis[0].intValue!
            if numberOfAxes >= naxis.count {
                // TODO Throw error
                return nil
            }
            var lengths = [Int]()
            for index in 0..<numberOfAxes {
                let axisLength = naxis[index + 1].intValue!
                lengths.append(axisLength)
            }
            self.init(bitPix: bitPix, byteZero: byteZero, numberOfAxes: numberOfAxes, lengthOfDataAxis: lengths, data: data)
            return
        }
        // TODO Throw error
        return nil
    }
    
    fileprivate init(bitPix: Int, byteZero: Int, numberOfAxes: Int, lengthOfDataAxis: [Int], data: Data) {
        self.isFloatingPoint = bitPix > 0 ? false : true
        self.bitsPerPixel = abs(bitPix)
        self.byteZero = byteZero
        self.numberOfAxes = numberOfAxes
        self.lengthOfDataAxis = lengthOfDataAxis
        // swap bytes from big endian
        self.data = FITSData.swapInt16Data(data: data, byteZero: self.byteZero)
        self.multipliers = [Int]()
        var multiplier = bitsPerPixel
        self.multipliers.append(multiplier)
        for index in 0..<(numberOfAxes-1) {
            multiplier = multiplier * lengthOfDataAxis[index]
            self.multipliers.insert(multiplier, at: 0)
        }
    }
    
    private static func swapInt16Data(data : Data, byteZero: Int) -> Data {
        var mdata = data // make a mutable copy
        let count = data.count / MemoryLayout<Int16>.size
        var min = UInt16.max
        var max = UInt16.min
        var newBytes : [UInt16] = [UInt16](repeating: UInt16(0), count: data.count)
        mdata.withUnsafeMutableBytes { (i16ptr: UnsafeMutablePointer<Int16>) in
            for i in 0..<count {
                //print("big endian byte[\(i)] = \(i16ptr[i])")
                let be = Int16(bigEndian: i16ptr[i])
                newBytes[i] = UInt16(Int(be) + byteZero)
                if newBytes[i] < min {
                    min = newBytes[i]
                }
                if newBytes[i] > max {
                    max = newBytes[i]
                }
              //  print("byte[\(i)] = \(newBytes[i])   [\(min),\(max)]")
            }
            print("--> Range  [\(min),\(max)]")
        }
        return Data(bytes: newBytes, count: data.count)
    }
    
    public func pixelIntValue(at index: [Int]) -> Int? {
        if index.count == self.numberOfAxes {
            var pos = 0
            for i in 0..<index.count {
                if index[i] >= lengthOfDataAxis[i] {
                    return nil
                }
                pos = pos + self.multipliers[i] * index[i]
                // TODO: implement
                // get bytes
                // use extension of Data to get the Int
                // return the int
            }
            return nil
        } else {
            return nil
        }
    }
    
    public func pixelDoubleValue(at index: [Int]) -> Double? {
        if index.count == self.numberOfAxes {
            var pos = 0
            for i in 0..<index.count {
                if index[i] >= lengthOfDataAxis[i] {
                    return nil
                }
                pos = pos + self.multipliers[i] * index[i]
                // TODO: implement
                // get bytes
                // use extension of Data to get the Double
                // return the Double
            }
            return nil
        } else {
            return nil
        }
    }
    
    /**
     * The size of the data in bits.
     */
    public var size : Int {
        get {
            self.data.count * 8
        }
    }
    
    public var image : CGImage? {
        get {
            if numberOfAxes == 2 {
                var cgImage : CGImage? = nil
                let colorspace = CGColorSpaceCreateDeviceGray()
                let bytes = self.data.bytes
                let cfdata = CFDataCreate(nil, bytes, data.count)
                let provider = CGDataProvider(data: cfdata!);
                var bitmapInfo : CGBitmapInfo = []
                switch self.bitsPerPixel {
                case 16:
                    bitmapInfo = [.byteOrderMask,.byteOrder16Big]
                case 32:
                    bitmapInfo = [.byteOrderMask,.byteOrder32Little]
                default:
                    break
                }
                cgImage = CGImage(width: lengthOfDataAxis[0], height: lengthOfDataAxis[1], bitsPerComponent: self.bitsPerPixel, bitsPerPixel: self.bitsPerPixel, bytesPerRow: lengthOfDataAxis[0]*self.bitsPerPixel/8, space: colorspace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent);
                return cgImage
            }
            return nil
        }
    }
}

// From: https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data

extension Data {

    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }

    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
    
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}

extension Data {

    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}
