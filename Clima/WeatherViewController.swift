//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Modified by Tony Xu on 03/26/2018.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    //Constants
    private let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    private let APP_ID = "9def5a84f246eddf19f474ac181d71f1"
    
    //TODO: Declare instance variables here
    private let locationManager = CLLocationManager()
    private let weatherDataModel = WeatherDataModel()
    
    
    //Pre-linked IBOutlets
    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var weatherIcon: UIImageView!
    @IBOutlet private weak var cityLabel: UILabel!
    @IBOutlet private weak var temperatureLabel: UILabel!
    
    private var refreshControll: UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        scroll.addSubview(refreshControll)
        refreshControll.addTarget(self,
                                  action: #selector(didPullToRefresh(sender:)),
                                  for: .valueChanged)
    }
    
    
    private func setupLocationManager() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    @objc private func didPullToRefresh(sender: Any) {
        locationManager.requestLocation()
    }
    
    private func getWeatherData(url: String, parameters: [String: String]) {
        
        AF.request(url, method: .get, parameters: parameters).responseJSON { [weak self] (response) in
            self?.refreshControll.endRefreshing()
            switch response.result {
            case .success(let value):
                self?.updateWeatherData(json: JSON(value))
            case .failure(let error):
                self?.cityLabel.text = "Network Error \(error.localizedDescription)"
            }
        }
    }
    
    private func updateWeatherData(json : JSON) {
        if let tempResult = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(tempResult - 273.15)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
        } else {
            cityLabel.text = "Unavailable"
        }
    }
    
    private func updateUIWithWeatherData() {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature)"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            
            locationManager.stopUpdatingLocation()
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            let params : [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
    }
}
