//
//  ViewController.swift
//  Regions
//
//  Created by doudou on 8/26/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class RegionViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource
{
	enum EventState
	{
		case Enter
		case Exit
	}
	
	struct RegionMonitorEvent
	{
		let region:CLCircularRegion
		let timestamp:NSDate
		let state:EventState
	}
	
	let LAT_SPAN:CLLocationDistance = 500.0
	let LON_SPAN:CLLocationDistance = 500.0
	let MONITOR_RADIUS:CLLocationDistance = 50.0
                            
	@IBOutlet weak var map: MKMapView!
	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet var insertButton: UIBarButtonItem!
	@IBOutlet var searchButton: UIBarButtonItem!
	
	private var locationManager:CLLocationManager!
	private var location:CLLocation!
	
	private var deviceAnnotation:DeviceAnnotation!
	private var isUpdated:Bool!

	private var placemark:CLPlacemark!
	private var heading:CLHeading!
	
	private var monitorEvents:[RegionMonitorEvent]!
	
	private var dateFormatter:NSDateFormatter!
	
	private var geocoder:CLGeocoder!
	private var geotime:NSDate!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		monitorEvents = []
		
		dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
		
		geocoder = CLGeocoder()
		
		tableView.alpha = 0.0
		tableView.hidden = true
		
		map.region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: 22.55, longitude: 113.94), LAT_SPAN, LON_SPAN)
		
		locationManager = CLLocationManager()
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestAlwaysAuthorization()
		locationManager.delegate = self
		locationManager.startUpdatingLocation()
		
		if CLLocationManager.headingAvailable()
		{
			locationManager.headingFilter = 1.0
			locationManager.startUpdatingHeading()
		}
		
		for region in locationManager.monitoredRegions
		{
			locationManager.stopMonitoringForRegion(region as CLRegion)
		}
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
	
	override func viewWillAppear(animated: Bool)
	{
		isUpdated = false
	}
	
	//MARK: 滚动列表展示
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		var cell = tableView.dequeueReusableCellWithIdentifier("RegionEventCell") as UITableViewCell!
		
		var text = ""
		var event = monitorEvents[indexPath.row]
		
		switch event.state
		{
			case .Enter:
				text += "进入"
			case .Exit:
				text += "走出"
		}
		
		text += " \(dateFormatter.stringFromDate(event.timestamp))"
		cell.textLabel?.text = text
		return cell
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return monitorEvents.count
	}
	
	//MARK: 页签组件切换
	@IBAction func segementChanged(sender: UISegmentedControl)
	{
		let duration:NSTimeInterval = 0.4
		if sender.selectedSegmentIndex == 0
		{
			navigationItem.setLeftBarButtonItem(searchButton, animated: true)
			navigationItem.setRightBarButtonItem(insertButton, animated: true)
			
			map.hidden = false
			UIView.animateWithDuration(duration,
			animations:
			{
				self.map.alpha = 1.0
				self.tableView.alpha = 0.0
			},
			completion:
			{
				(flag) in
				self.tableView.hidden = true
			})
		}
		else
		{
			navigationItem.setLeftBarButtonItem(nil, animated: true)
			navigationItem.setRightBarButtonItem(nil, animated: true)
			
			tableView.reloadData()
			
			tableView.hidden = false
			UIView.animateWithDuration(duration / 2.0, animations:
			{
				self.map.alpha = 0.0
				self.tableView.alpha = 1.0
			},
			completion:
			{
				(flag) in
				self.map.hidden = true
			})
		}
		
		UIView.commitAnimations()
	}
	
	//MARK: 按钮交互
	@IBAction func showDeviceLocation(sender: UIBarButtonItem)
	{
		if map.userLocation != nil
		{
			map.setRegion(MKCoordinateRegionMakeWithDistance(map.userLocation.coordinate, LAT_SPAN, LON_SPAN), animated: true)
		}
	}

	@IBAction func inertMonitorRegion(sender: UIBarButtonItem)
	{
		if (location == nil || map.userLocation == nil)
		{
			return
		}
		
		var lat = map.userLocation.coordinate.latitude - location.coordinate.latitude
		var lon = map.userLocation.coordinate.longitude - location.coordinate.longitude
		
		var region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: map.centerCoordinate.latitude - lat, longitude: map.centerCoordinate.longitude - lon),
									  radius: MONITOR_RADIUS,
								  identifier: String(format:"%.8f-%.8f", map.centerCoordinate.latitude, map.centerCoordinate.longitude))
		
		var annotation = RegionAnnotation(coordinate: map.centerCoordinate, region: region)
		
		map.addAnnotation(annotation)
		map.addOverlay(MKCircle(centerCoordinate: annotation.coordinate, radius: MONITOR_RADIUS))
		
		if CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion)
		{
			locationManager.startMonitoringForRegion(region)
		}
	}
	
	//MARK: 地图相关
	func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
	{
		if annotation.isKindOfClass(DeviceAnnotation)
		{
			let identifier = "DeviceAnnotationView"
			var anView = map.dequeueReusableAnnotationViewWithIdentifier(identifier) as MKPinAnnotationView!
			if anView == nil
			{
				anView = MKPinAnnotationView(annotation: deviceAnnotation, reuseIdentifier: identifier)
				anView.canShowCallout = true
				anView.pinColor = MKPinAnnotationColor.Purple
			}
			else
			{
				anView.annotation = annotation
			}
			
			if placemark != nil
			{
				var button = UIButton.buttonWithType(.DetailDisclosure) as UIButton
				button.addTarget(self, action: "displayPlacemarkInfo", forControlEvents: UIControlEvents.TouchUpInside)
				anView.rightCalloutAccessoryView = button
			}
			else
			{
				anView.rightCalloutAccessoryView = nil
			}
			
			return anView
		}
		else
		if annotation.isKindOfClass(RegionAnnotation)
		{
			let identifier = "RegionAnnotationView"
			var anView = map.dequeueReusableAnnotationViewWithIdentifier(identifier) as MKPinAnnotationView!
			if anView == nil
			{
				anView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
				anView.canShowCallout = true
				anView.pinColor = MKPinAnnotationColor.Green
			}
			else
			{
				anView.annotation = annotation
			}
			
			return anView
		}
		
		return nil
	}
	
	func displayPlacemarkInfo()
	{
		var locationCtrl = PlacemarkViewController(nibName: "PlacemarkInfoView", bundle: nil)
		locationCtrl.placemark = placemark
		
		navigationController?.pushViewController(locationCtrl, animated: true)
		
	}
	
	func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer!
	{
		if overlay.isKindOfClass(MKCircle)
		{
			var render = MKCircleRenderer(overlay: overlay)
			render.strokeColor = UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.5)
			render.fillColor = UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.2)
			render.lineWidth = 1.0
			return render
		}
		
		return nil
	}
	
	//MARK: 方向定位
	func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!)
	{
		heading = newHeading
	}
	
	//MARK: 定位相关
	func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!)
	{
		location = newLocation
		
		var chinaloc = ChinaGPS.encrypt(newLocation)
		if deviceAnnotation == nil
		{
			deviceAnnotation = DeviceAnnotation(coordinate: chinaloc.coordinate)
			map.addAnnotation(deviceAnnotation)
		}
		else
		{
			deviceAnnotation.coordinate = chinaloc.coordinate
		}
		
		deviceAnnotation.update(location:chinaloc)
		if geotime == nil || fabs(geotime.timeIntervalSinceNow) > 10.0
		{
			geotime = NSDate()
			
			println("geocode", geotime.description)
			geocoder.reverseGeocodeLocation(chinaloc,
			completionHandler:
			{
				(placemarks, error) in
				if error == nil
				{
					self.processPlacemark(placemarks as [CLPlacemark])
				}
				else
				{
					println(error)
				}
			});
		}

		map.selectAnnotation(deviceAnnotation, animated: false)
	}
	
	func processPlacemark(placemarks:[CLPlacemark])
	{
		var initialized = !(self.placemark == nil)
		
		placemark = placemarks.first!
		if placemark != nil && !initialized
		{
			map.removeAnnotation(deviceAnnotation)
			
			map.addAnnotation(deviceAnnotation)
			map.selectAnnotation(deviceAnnotation, animated: true)
		}
		
		if placemark != nil
		{
			deviceAnnotation.update(placemark: placemark)
		}
	}
	
	func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!)
	{
		var event = RegionMonitorEvent(region: region as CLCircularRegion, timestamp: NSDate(), state: .Enter)
		monitorEvents.append(event)
		if !tableView.hidden
		{
			tableView.reloadData()
		}
	}
	
	func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!)
	{
		var event = RegionMonitorEvent(region: region as CLCircularRegion, timestamp: NSDate(), state: .Exit)
		monitorEvents.append(event)
		if !tableView.hidden
		{
			tableView.reloadData()
		}
	}
	
	func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!)
	{
		UIAlertView(title: "区域监听失败", message: error?.description, delegate: nil, cancelButtonTitle: "我知道了").show()
	}
	
	//MARK: 地图相关
	func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!)
	{
		if !isUpdated
		{
			map.setCenterCoordinate(userLocation.coordinate, animated: true)
			isUpdated = true
		}
	}
}

	