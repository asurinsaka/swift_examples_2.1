//
//  ViewController.swift
//  AutoLayout
//
//  Created by larryhou on 3/21/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		updateConstraints()
	}
	
	func updateConstraints()
	{
		let label = view.viewWithTag(1)! as! UILabel
		label.font = UIFont.systemFontOfSize(16)
		label.text = "Created By Visual Format Language"
		label.removeFromSuperview()
		
        label.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(label)


        var map = [String:AnyObject]()
        map["label"] = label


		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: map))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label(30)]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: map))
	
		let pad1 = UIView()
		pad1.translatesAutoresizingMaskIntoConstraints = false
		pad1.backgroundColor = UIColor.blueColor()
		map.updateValue(pad1, forKey: "pad1")
		view.addSubview(pad1)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[pad1(1)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: map))
		
		let pad2 = UIView()
		pad2.translatesAutoresizingMaskIntoConstraints = false
		map.updateValue(pad2, forKey: "pad2")
		view.addSubview(pad2)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[pad2(1)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: map))

		let name = UILabel()
		name.text = "LARRY HOU"
		name.font = UIFont.systemFontOfSize(30)
		name.textAlignment = NSTextAlignment.Center
		name.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(name)
		
		map.updateValue(name, forKey: "name")
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[name]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: map))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[pad1]-[name(30)]-[pad2(==pad1)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: map))
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

