//
//  ByteArrayTests.swift
//  ByteArrayTests
//
//  Created by larryhou on 5/20/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import XCTest

class ByteArrayTests: XCTestCase
{
    func testReadBoolean()
    {
        let bytes = ByteArray()
        
        var value = UInt8(arc4random_uniform(2))
        bytes.data.appendBytes(&value, length: 1)
        
        bytes.position = 0
        XCTAssertEqual(bytes.readBoolean(), Bool(Int(value)))
    }
    
    func testReadInt8()
    {
        let bytes = ByteArray()
        for i in 0...0xFF
        {
            var byte = UInt8(arc4random_uniform(0xFF))
            let data = NSData(bytes: &byte, length: 1)
            
            var value:Int8 = 0
            data.getBytes(&value, length: 1)
            bytes.data.appendBytes(&value, length: 1)
            
            XCTAssertEqual(bytes.readInt8(), value)
        }
    }
    
    func testWriteInt()
    {
        let endian = ByteArray.Endian.LITTLE_ENDIAN
        
        let bytes = ByteArray()
        bytes.endian = endian
        
        for n in 0...5000
        {
            let value = Int(arc4random())
            let position = Int(arc4random_uniform(UInt32(bytes.length)))
            
            bytes.position = position
            bytes.writeInt64(value)
            
            var num = 0
            bytes.data.getBytes(&num, range: NSRange(location: position, length: 8))
            if endian == .BIG_ENDIAN
            {
                XCTAssertEqual(value, num.bigEndian)
            }
            else
            {
                XCTAssertEqual(value, num)
            }
        }
        
    }
    
    func testReadInt()
    {
        let endian = ByteArray.Endian.BIG_ENDIAN
        
        var list:[Int] = []
        let data = NSMutableData()
        for n in 0...10000
        {
            var value = Int(arc4random())
            
            list.append(value)
            if endian == .BIG_ENDIAN
            {
                value = value.bigEndian
            }
            
            data.appendBytes(&value, length: 8)
        }
        
        XCTAssertEqual(data.length % 8, 0)
        
        let bytes = ByteArray(data: data)
        bytes.endian = endian
        
        for n in 0...5000
        {
            let index = Int(arc4random_uniform(UInt32(list.count)))
            
            bytes.position = index * 8
            XCTAssertEqual(list[index], bytes.readInt64())
        }
    }
    
    func testWriteInt8()
    {
        let value:Int8 = -25
        let bytes = ByteArray()
        bytes.writeInt8(value)
        
        bytes.position = 0
        XCTAssertEqual(value, bytes.readInt8())
    }
    
    func testWriteInt16()
    {
        let value:Int16 = -2500
        let bytes = ByteArray()
        bytes.endian = .BIG_ENDIAN
        bytes.writeInt16(value)
        
        bytes.position = 0
        XCTAssertEqual(value, bytes.readInt16())
    }
    
    func testWriteDouble()
    {
        let endian = ByteArray.Endian.LITTLE_ENDIAN
        
        let bytes = ByteArray()
        bytes.endian = endian
        
        for n in 0...5000
        {
            let value = Double(arc4random()) / Double(UInt32.max)
            let position = Int(arc4random_uniform(UInt32(bytes.length)))
            
            bytes.position = position
            bytes.writeDouble(value)
            
            var num = 0.0
            if endian == .BIG_ENDIAN
            {
                var mem = [UInt8](count: 8, repeatedValue: 0)
                
                bytes.data.getBytes(&mem, range: NSRange(location: position, length: mem.count))
                num = UnsafePointer<Double>(Array(mem.reverse())).memory
            }
            else
            {
                bytes.data.getBytes(&num, range: NSRange(location: position, length: 8))
            }
            
            XCTAssertEqual(value, num)
        }
    }
    
    func testReadDouble()
    {
        let endian = ByteArray.Endian.BIG_ENDIAN
        
        var list:[Double] = []
        let data = NSMutableData()
        for n in 0...10000
        {
            var value = Double(arc4random()) / Double(UInt32.max)
            
            list.append(value)
            if endian == .BIG_ENDIAN
            {
                let mem = Array(ByteArray.dump(value).reverse())
                value = UnsafePointer<Double>(mem).memory
            }
            
            data.appendBytes(&value, length: 8)
        }
        
        XCTAssertEqual(data.length % 8, 0)
        
        let bytes = ByteArray(data: data)
        bytes.endian = endian
        
        for n in 0...5000
        {
            let index = Int(arc4random_uniform(UInt32(list.count)))
            
            bytes.position = index * 8
            XCTAssertEqual(list[index], bytes.readDouble())
        }
    }
    
    func testEndian()
    {
        let bytes = ByteArray()
        bytes.endian = .LITTLE_ENDIAN
        
        bytes.writeDouble(M_PI)
        
        var list = ByteArray.dump(M_PI)
        for i in 0..<bytes.length
        {
            XCTAssertEqual(list[i], bytes[i])
        }
        
        bytes.clear()
        bytes.endian = .BIG_ENDIAN
        bytes.writeDouble(M_PI)
        
        list = Array(list.reverse())
        for i in 0..<bytes.length
        {
            XCTAssertEqual(list[i], bytes[i])
        }
    }
    
    func testWriteUTFBytes()
    {
        let text = "侯坤峰侯坤峰侯坤峰侯坤峰"
        
        let bytes = ByteArray()
        bytes.writeUTFBytes(text)
        
        let data = NSString(string: text).dataUsingEncoding(NSUTF8StringEncoding)!
        
        XCTAssertEqual(data.length, bytes.length)
        
        for i in 0..<data.length
        {
            var value:UInt8 = 0
            data.getBytes(&value, range: NSRange(location: i, length: 1))
            
            XCTAssertEqual(bytes[i], value)
        }
    }
    
    func testReadUTFBytes()
    {
        let text = "侯坤峰侯坤峰侯坤峰侯坤峰"
        
        let bytes = ByteArray()
        let data = NSString(string: text).dataUsingEncoding(NSUTF8StringEncoding)!
        bytes.data.appendData(data)
        
        bytes.position = 0
        XCTAssertEqual(text, bytes.readUTFBytes(data.length))
    }
    
    func testReadMultiBytes()
    {
        let text = "侯坤峰侯坤峰侯坤峰侯坤峰"
        
        let bytes = ByteArray()
        let encoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        let charset = CFStringConvertEncodingToNSStringEncoding(encoding)
        
        let data = NSString(string: text).dataUsingEncoding(charset)!
        bytes.data.appendData(data)
        
        bytes.position = 0
        XCTAssertEqual(text, bytes.readMultiByte(data.length, encoding: encoding))
    }
    
    func testWriteMultiBytes()
    {
        let text = "侯坤峰侯坤峰侯坤峰侯坤峰"
        let bytes = ByteArray()
        
        let encoding = CFStringEncoding(CFStringEncodings.EUC_TW.rawValue)
        bytes.writeMultiBytes(text, encoding: encoding)
        
        bytes.position = 0
        XCTAssertEqual(text, bytes.readMultiByte(bytes.length, encoding: encoding))
    }
    
    func testReadBytes()
    {
        let data = NSString(string: "侯坤峰侯坤峰侯坤峰侯坤峰").dataUsingEncoding(NSUTF8StringEncoding)!
        let bytes = ByteArray(data: data)
        
        let refer = ByteArray()
        
        var value = M_PI
        for n in 0...5000
        {
            if n % 20 == 0
            {
                refer.clear()
                refer.data.appendBytes(&value, length: sizeof(Double))
            }
            
            let bytesOffset = Int(arc4random_uniform(UInt32(bytes.length - 2)) + 1)
            let referOffset = Int(arc4random_uniform(UInt32(refer.length * 2)) + 1)
            
            let num = Int(arc4random_uniform(UInt32(data.length - bytesOffset)) + 1)
            
            bytes.position = bytesOffset
            bytes.readBytes(refer, offset: referOffset, length: num)
            
            for i in 0..<num
            {
                XCTAssertEqual(refer[i + referOffset], bytes[i + bytesOffset])
            }
        }
    }
    
    func testWriteBytes()
    {
        let data = NSString(string: "侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰侯坤峰").dataUsingEncoding(NSUTF8StringEncoding)!
        let bytes = ByteArray(data: data)
        
        let refer = ByteArray()
        
        for n in 0...5000
        {
            if n % 20 == 0
            {
                refer.clear()
                refer.data.appendData(NSString(string: "larryhoularryhoularryhoularryhoularryhou").dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            
            let referOffset = Int(arc4random_uniform(UInt32(refer.length - 2)) + 1)
            let bytesOFfset = Int(arc4random_uniform(UInt32(bytes.length)) + 1)
            
            let num = Int(arc4random_uniform(UInt32(refer.length - referOffset)) + 1)
            
            bytes.position = bytesOFfset
            bytes.writeBytes(refer, offset: referOffset, length: num)
            
            for i in 0..<num
            {
                XCTAssertEqual(bytes[i + bytesOFfset], refer[i + referOffset])
            }
        }
    }
    
    func testValueDump()
    {
        var value = M_PI
        
        let data = NSData(bytes: &value, length: sizeof(Double))
        
        var mem1 = ByteArray.dump(&value)
        var mem2 = ByteArray.dump(value)
        
        XCTAssertEqual(mem1.count, mem2.count)
        
        for i in 0..<mem1.count
        {
            var byte:UInt8 = 0
            data.getBytes(&byte, range: NSRange(location: i, length: 1))
            
            XCTAssertEqual(byte, mem1[i])
            XCTAssertEqual(mem1[i], mem2[i])
        }
    }
    
    func testPerformanceExample()
    {
        self.measureBlock()
        {
            self.testReadBytes()
        }
    }
    
}
