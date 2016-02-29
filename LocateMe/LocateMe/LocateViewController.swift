//
//  LocateViewController.swift
//  LocateMe
//
//  Created by doudou on 8/17/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

extension CLAuthorizationStatus
{
    var description:String
    {
        var status:String
        switch self
        {
            case .Authorized:status="Authorized"
            case .AuthorizedWhenInUse:status="AuthorizedWhenInUse"
            case .Denied:status="Denied"
            case .NotDetermined:status="NotDetermined"
            case .Restricted:status="Restriced"
        }
            
        return "CLAuthorizationStatus.\(status)"
    }
}

class LocateViewController:UITableViewController, SetupSettingReceiver, CLLocationManagerDelegate
{
	enum LocationUpdateStatus:String
	{
		case Updating = "Updating"
		case Timeout = "Timeout"
		case Acquired = "Acquired Location"
		case Error = "Error"
		case None = "None"
	}

    enum SectionType:Int
    {
        case LocateStatus = 0
        case BestMeasurement = 1
        case Measurements = 2
    }

	enum CellIdentifier:String
	{
		case Status = "StatusCell"
		case Measurement = "MeasurementCell"
	}
    
    private var setting:LocateSettingInfo!
    private var dateFormatter:NSDateFormatter!
	private var leftFormatter:NSNumberFormatter!
	
	private var bestMeasurement:CLLocation!
	private var measurements:[CLLocation]!
	
	private var locationManager:CLLocationManager!
	private var timer:NSTimer!

	private var remainTime:Float!
	
	private var status:LocationUpdateStatus!
    
    func setupSetting(setting: LocateSettingInfo)
    {
        self.setting = setting
    }
    
    override func viewDidLoad()
    {
        dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = localizeString("DateFormat")

		leftFormatter = NSNumberFormatter()
		leftFormatter.minimumIntegerDigits = 2
		leftFormatter.maximumFractionDigits = 0
		
        measurements = []
		locationManager = CLLocationManager()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        if bestMeasurement == nil
        {
            startUpdateLocation()
        }
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		stopUpdatingLocation(.None)
	}
	
	// MARK: 数据重置
    @IBAction func refresh(sender: UIBarButtonItem)
    {
        startUpdateLocation()
    }
	
	// MARK: 定位相关
    func startUpdateLocation()
    {
        if timer != nil
        {
            timer.invalidate()
            timer = nil
        }
        
        locationManager.stopUpdatingLocation()
        
        measurements.removeAll(keepCapacity: false)
        bestMeasurement = nil
        
        status = .Updating
        tableView.reloadData()
        
        print(setting)
        
        remainTime = setting.sliderValue
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
            target: self, selector: "timeTickUpdate",
            userInfo: nil, repeats: true)
        
        // FIXME: 无法使用带参数的selector，否则报错： [NSCFTimer copyWithZone:]: unrecognized selector sent to instance
        //			timer = NSTimer.scheduledTimerWithTimeInterval(delay,
        //			target: self, selector: "stopUpdatingLocation:",
        //			userInfo: nil, repeats: false)
        
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse)
        {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.desiredAccuracy = setting.accuracy
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation(status:LocationUpdateStatus)
    {
        if status != .None
        {
            self.status = status
            tableView.reloadData()
        }
        
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        
        if timer != nil
        {
            timer.invalidate()
            timer = nil
        }
    }
    
    func timeTickUpdate()
    {
		remainTime!--
		tableView.reloadData()
		
		if remainTime <= 0
        {
			stopUpdatingLocation(.Timeout)
		}
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        print("authorization:\(status.description)")
    }
    
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
	{
        for data in locations
        {
            let location = data as CLLocation
            
            measurements.append(location)
            
            if bestMeasurement == nil || bestMeasurement.horizontalAccuracy > location.horizontalAccuracy
            {
                bestMeasurement = location
                if location.horizontalAccuracy < locationManager.desiredAccuracy
                {
                    stopUpdatingLocation(.Acquired)
                }
            }
        }
        
        tableView.reloadData()
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
	{
		stopUpdatingLocation(.Error)
	}
	
	// MARK: 列表展示
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return bestMeasurement != nil ? 3 : 1
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		switch SectionType(rawValue: indexPath.section)!
		{
			case .LocateStatus:return 60.0 //FIXME: 自定义UITableViewCell需要手动指定高度
			default:return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
		}
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if let type = SectionType(rawValue: section)
		{
			switch type
			{
				case .LocateStatus:
					return localizeString("Status")
				
				case .BestMeasurement:
					return localizeString("Best Measurement")
				
				case .Measurements:
					return localizeString("All Measurements")
			}
		}
		else
		{
			return nil
		}
		
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if let type = SectionType(rawValue: section)
		{
			switch type
			{
				case .LocateStatus:return 1
				case .BestMeasurement:return 1
				case .Measurements:return measurements.count
			}
		}
		else
		{
			return 0
		}
	}
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let type = SectionType(rawValue: indexPath.section)
        {
            switch type
            {
            case .LocateStatus:
                let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Status.rawValue) as! StatusTableViewCell
                cell.timeTicker.text = leftFormatter.stringFromNumber(remainTime)
                cell.label.text = localizeString(status.rawValue)
                if status == .Updating
                {
                    cell.timeTicker.alpha = 1.0
                    if !cell.indicator.isAnimating()
                    {
                        cell.indicator.startAnimating()
                    }
                }
                else
                {
                    cell.timeTicker.alpha = 0.0
                    if cell.indicator.isAnimating()
                    {
                        cell.indicator.stopAnimating()
                    }
                }
                return cell
                
            case .BestMeasurement:
                let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.rawValue)! as UITableViewCell
                cell.textLabel!.text = bestMeasurement.getCoordinateString()
                cell.detailTextLabel!.text = dateFormatter.stringFromDate(bestMeasurement.timestamp)
                return cell
                
            case .Measurements:
                let location = measurements[indexPath.row]
                let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.rawValue)! as UITableViewCell
                
                cell.textLabel!.text = location.getCoordinateString()
                cell.detailTextLabel!.text = dateFormatter.stringFromDate(location.timestamp)
                return cell
            }
        }
        else{
            return UITableViewCell()
        }
    }
    
    
    
    
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }
    
	
	//MARK: segue
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)
	{
		if segue.identifier == "LocationDetailSegue"
		{
			let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
			let type:SectionType = SectionType(rawValue: indexPath!.section)!
			
			let destinationCtrl = segue.destinationViewController as! LocationDetailViewController
			
			switch type
			{
				case .BestMeasurement:
					destinationCtrl.location = bestMeasurement
				case .Measurements:
					destinationCtrl.location = measurements[indexPath!.row]
				default:break
			}
		}
	}
	
}
