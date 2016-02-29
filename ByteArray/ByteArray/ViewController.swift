//
//  ViewController.swift
//  ByteArray
//
//  Created by larryhou on 5/20/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let bytes = ByteArray()
        bytes.endian = .BIG_ENDIAN
        
        bytes.writeBoolean(true)
        bytes.writeUTF("侯坤峰")
        bytes.writeDouble(M_PI)
        bytes.writeUTF("侯坤峰")
        bytes.writeUTF("侯坤峰")
        bytes.writeUTF("侯坤峰")
        bytes.writeUTF("侯坤峰")
        
        print(bytes.position)
        
        bytes.position = 0
        print(bytes.readBoolean())
        print(bytes.readUTF())
        print(bytes.readDouble())
        
        let data = ByteArray()
        data.endian = bytes.endian
        
//        bytes.position = 1
//        bytes.readBytes(data, offset: 0, length: 11)
        
        data.writeBytes(bytes, offset: 1, length: 11)
        
        print(data.length)
        data.position = 0
        print(data.readUTF())
        
        print(ByteArray.hexe(bytes, range: NSRange(location: 0, length: bytes.length)))
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

