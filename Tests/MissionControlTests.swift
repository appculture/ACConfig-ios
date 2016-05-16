//
//  MissionControlTests.swift
//  MissionControlTests
//
//  Created by Marko Tadic on 5/13/16.
//  Copyright © 2016 appculture. All rights reserved.
//

import XCTest
@testable import MissionControl

class MissionControlTests: XCTestCase {
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        MissionControl.sharedInstance.reset()
        
        super.tearDown()
    }
    
    // MARK: - Helper Properties
    
    struct URL {
        static let BadResponseConfig = NSURL(string: "http://appculture.com/not-existing-config.json")!
        static let EmptyDataConfig = NSURL(string: "http://private-83024-acconfig.apiary-mock.com/acconfig/empty-config")!
        static let InvalidDataConfig = NSURL(string: "http://private-83024-acconfig.apiary-mock.com/acconfig/invalid-config")!
        static let RemoteTestConfig = NSURL(string: "http://private-83024-acconfig.apiary-mock.com/acconfig/test-config")!
    }
    
    struct ConfigKey {
        static let TestBool = "TestBool"
        static let TestInt = "TestInt"
        static let TestDouble = "TestDouble"
        static let TestString = "TestString"
    }
    
    let localTestConfig: [String : AnyObject] = [
        ConfigKey.TestBool : false,
        ConfigKey.TestInt : 21,
        ConfigKey.TestDouble : 0.8,
        ConfigKey.TestString : "Local"
    ]
    
    let remoteTestConfig: [String : AnyObject] = [
        ConfigKey.TestBool : true,
        ConfigKey.TestInt : 8,
        ConfigKey.TestDouble : 2.1,
        ConfigKey.TestString : "Remote"
    ]
    
    // MARK: - Test Initial State
    
    func testInitialSettings() {
        let settings = Config.settings
        XCTAssertEqual(settings.count, 0, "Initial settings should be empty but not nil.")
    }
    
    func testInitialLastRefreshDate() {
        let date = Config.lastRefreshDate
        XCTAssertNil(date, "Initial last refresh date should be nil.")
    }
    
    func testInitialAccessorsWithoutDefaultValues() {
        let bool = ConfigBool(ConfigKey.TestBool)
        XCTAssertEqual(bool, false, "Should default to false.")
        
        let int = ConfigInt(ConfigKey.TestInt)
        XCTAssertEqual(int, 0, "Should default to 0.")
        
        let double = ConfigDouble(ConfigKey.TestDouble)
        XCTAssertEqual(double, 0.0, "Should default to 0.0.")
        
        let string = ConfigString(ConfigKey.TestString)
        XCTAssertEqual(string, String(), "Should default to empty string.")
    }
    
    func testInitialAccessorsWithDefaultValues() {
        let bool = ConfigBool(ConfigKey.TestBool, true)
        XCTAssertEqual(bool, true, "Should default to given value.")
        
        let int = ConfigInt(ConfigKey.TestInt, 1984)
        XCTAssertEqual(int, 1984, "Should default to given value.")
        
        let double = ConfigDouble(ConfigKey.TestDouble, 21.08)
        XCTAssertEqual(double, 21.08, "Should default to given value.")
        
        let string = ConfigString(ConfigKey.TestString, "Hello")
        XCTAssertEqual(string, "Hello", "Should default to given value.")
    }
    
    // MARK: - Test Launch Without Parameters
    
    func testLaunchWithoutParameters() {
        Config.launch()
        confirmInitialState()
    }
    
    func confirmInitialState() {
        testInitialSettings()
        testInitialLastRefreshDate()
        
        testInitialAccessorsWithDefaultValues()
        testInitialAccessorsWithoutDefaultValues()
    }
    
    // MARK: - Test Launch With Local Config
    
    func testLaunchWithLocalConfig() {
        Config.launch(localConfig: localTestConfig)
        confirmLocalConfigState()
    }
    
    func confirmLocalConfigState() {
        let settings = Config.settings
        XCTAssertEqual(settings.count, 4, "Initial settings should contain given local config.")
        
        let date = Config.lastRefreshDate
        XCTAssertNotNil(date, "Initial last refresh date should not be nil.")
        
        confirmLocalConfigAccessorsWithoutDefaultValues()
        confirmLocalConfigAccessorsWithDefaultValues()
    }
    
    func confirmLocalConfigAccessorsWithDefaultValues() {
        let bool = ConfigBool(ConfigKey.TestBool, true)
        let expectedBool = localTestConfig[ConfigKey.TestBool] as! Bool
        XCTAssertEqual(bool, expectedBool, "Should default to value in local test config.")
        
        let int = ConfigInt(ConfigKey.TestInt, 1984)
        let expectedInt = localTestConfig[ConfigKey.TestInt] as! Int
        XCTAssertEqual(int, expectedInt, "Should default to value in local test config.")
        
        let double = ConfigDouble(ConfigKey.TestDouble, 21.08)
        let expectedDouble = localTestConfig[ConfigKey.TestDouble] as! Double
        XCTAssertEqual(double, expectedDouble, "Should default to value in local test config.")
        
        let string = ConfigString(ConfigKey.TestString, "Default")
        let expectedString = localTestConfig[ConfigKey.TestString] as! String
        XCTAssertEqual(string, expectedString, "Should default to value in local test config.")
    }
    
    func confirmLocalConfigAccessorsWithoutDefaultValues() {
        let bool = ConfigBool(ConfigKey.TestBool)
        let expectedBool = localTestConfig[ConfigKey.TestBool] as! Bool
        XCTAssertEqual(bool, expectedBool, "Should default to value in local test config.")
        
        let int = ConfigInt(ConfigKey.TestInt)
        let expectedInt = localTestConfig[ConfigKey.TestInt] as! Int
        XCTAssertEqual(int, expectedInt, "Should default to value in local test config.")
        
        let double = ConfigDouble(ConfigKey.TestDouble)
        let expectedDouble = localTestConfig[ConfigKey.TestDouble] as! Double
        XCTAssertEqual(double, expectedDouble, "Should default to value in local test config.")
        
        let string = ConfigString(ConfigKey.TestString)
        let expectedString = localTestConfig[ConfigKey.TestString] as! String
        XCTAssertEqual(string, expectedString, "Should default to value in local test config.")
    }
    
    // MARK: - Test Launch With Remote Config
    
    func testLaunchWithRemoteConfig() {
        Config.launch(remoteConfigURL: URL.RemoteTestConfig)
        confirmInitialState()
        confirmRemoteConfigStateAfterNotification(Config.Notification.ConfigLoaded)
    }
    
    // MARK: - Test Launch With Local & Remote Config
    
    func testLaunchWithLocalAndRemoteConfig() {
        Config.launch(localConfig: localTestConfig, remoteConfigURL: URL.RemoteTestConfig)
        confirmLocalConfigState()
        
        /// - NOTE: ConfigLoaded notification was called during launch (by setting localConfig)
        confirmRemoteConfigStateAfterNotification(Config.Notification.ConfigRefreshed)
    }
    
    // MARK: - Test Refresh
    
    func testFirstRefresh() {
        Config.launch(remoteConfigURL: URL.RemoteTestConfig)
        
        /// - NOTE: refresh is called automatically during launch
        confirmRemoteConfigStateAfterNotification(Config.Notification.ConfigLoaded)
    }
    
    func testManualRefresh() {
        testFirstRefresh()
        Config.refresh()
        
        /// - NOTE: ConfigLoaded notification was called in testFirstRefresh()
        confirmRemoteConfigStateAfterNotification(Config.Notification.ConfigRefreshed)
    }
    
    func confirmRemoteConfigStateAfterNotification(notification: String) {
        let _ = expectationForNotification(notification, object: nil) { (notification) -> Bool in
            self.confirmRemoteConfigState()
            return true
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func confirmRemoteConfigState() {
        let settings = Config.settings
        XCTAssertEqual(settings.count, 4, "Initial settings should contain given local config.")
        
        let date = Config.lastRefreshDate
        XCTAssertNotNil(date, "Initial last refresh date should not be nil.")
        
        confirmRemoteConfigAccessorsWithDefaultValues()
        confirmRemoteConfigAccessorsWithoutDefaultValues()
    }
    
    func confirmRemoteConfigAccessorsWithDefaultValues() {
        let bool = ConfigBool(ConfigKey.TestBool)
        let expectedBool = remoteTestConfig[ConfigKey.TestBool] as! Bool
        XCTAssertEqual(bool, expectedBool, "Should default to value in remote test config.")
        
        let int = ConfigInt(ConfigKey.TestInt)
        let expectedInt = remoteTestConfig[ConfigKey.TestInt] as! Int
        XCTAssertEqual(int, expectedInt, "Should default to value in remote test config.")
        
        let double = ConfigDouble(ConfigKey.TestDouble)
        let expectedDouble = remoteTestConfig[ConfigKey.TestDouble] as! Double
        XCTAssertEqual(double, expectedDouble, "Should default to value in remote test config.")
        
        let string = ConfigString(ConfigKey.TestString)
        let expectedString = remoteTestConfig[ConfigKey.TestString] as! String
        XCTAssertEqual(string, expectedString, "Should default to value in remote test config.")
    }
    
    func confirmRemoteConfigAccessorsWithoutDefaultValues() {
        let bool = ConfigBool(ConfigKey.TestBool)
        let expectedBool = remoteTestConfig[ConfigKey.TestBool] as! Bool
        XCTAssertEqual(bool, expectedBool, "Should default to value in remote test config.")
        
        let int = ConfigInt(ConfigKey.TestInt)
        let expectedInt = remoteTestConfig[ConfigKey.TestInt] as! Int
        XCTAssertEqual(int, expectedInt, "Should default to value in remote test config.")
        
        let double = ConfigDouble(ConfigKey.TestDouble)
        let expectedDouble = remoteTestConfig[ConfigKey.TestDouble] as! Double
        XCTAssertEqual(double, expectedDouble, "Should default to value in remote test config.")
        
        let string = ConfigString(ConfigKey.TestString)
        let expectedString = remoteTestConfig[ConfigKey.TestString] as! String
        XCTAssertEqual(string, expectedString, "Should default to value in remote test config.")
    }
    
    // MARK: - Test Refresh Errors
    
    func testRefreshErrorNoRemoteURL() {
        Config.launch()
        
        /// - NOTE: refresh is NOT called automatically during launch (remote URL missing)
        let asyncExpectation = expectationWithDescription("manual-refresh-without-url")
        Config.refresh { (block) in
            do {
                let _ = try block()
                XCTAssert(false, "Should fall through to catch block!")
                asyncExpectation.fulfill()
            } catch {
                let message = "Should return NoRemoteURL error whene remoteURL is not set."
                XCTAssertEqual("\(error)", "\(Config.Error.NoRemoteURL)", message)
                asyncExpectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRefreshErrorBadResponseCode() {
        Config.launch(remoteConfigURL: URL.BadResponseConfig)
        /// - NOTE: refresh is called automatically during launch
        
        let message = "Should return BadResponseCode error when response is not 200 OK."
        confirmConfigRefreshFailedNotification(Config.Error.BadResponseCode, message: message)
    }
    
    func testRefreshErrorInvalidDataEmpty() {
        Config.launch(remoteConfigURL: URL.EmptyDataConfig)
        /// - NOTE: refresh is called automatically during launch
        
        let message = "Should return InvalidData error when response data is empty."
        confirmConfigRefreshFailedNotification(Config.Error.InvalidData, message: message)
    }
    
    func testRefreshErrorInvalidData() {
        Config.launch(remoteConfigURL: URL.InvalidDataConfig)
        /// - NOTE: refresh is called automatically during launch
        
        let message = "Should return InvalidData error when response data is not valid JSON."
        confirmConfigRefreshFailedNotification(Config.Error.InvalidData, message: message)
    }
    
    func confirmConfigRefreshFailedNotification(error: Config.Error, message: String) {
        let _ = expectationForNotification(Config.Notification.ConfigRefreshFailed, object: nil) { (notification) -> Bool in
            guard let errorInfo = notification.userInfo?["Error"] as? String else { return false }
            XCTAssertEqual("\(errorInfo)", "\(error)", message)
            self.confirmInitialState()
            return true
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
}
