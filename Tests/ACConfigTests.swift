//
//  ACConfigTests.swift
//  ACConfigTests
//
//  Created by Marko Tadic on 5/13/16.
//  Copyright © 2016 appculture. All rights reserved.
//

import XCTest
@testable import ACConfig

class ACConfigTests: XCTestCase {
    
    // MARK: - Set up / Tear Down / Helpers
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        ACConfig.sharedInstance.reset()
        
        super.tearDown()
    }
    
    let localConfig: [String : AnyObject] = [
        "LocalBool" : true,
        "LocalInt" : 8,
        "LocalDouble" : 0.21,
        "LocalString" : "Local"
    ]
    
    let remoteConfig: [String : AnyObject] = [
        "RemoteBool" : false,
        "RemoteInt" : 21,
        "RemoteDouble" : 0.8,
        "RemoteString" : "Remote"
    ]
    
    // MARK: - Test Properties
    
    func testInitialSettings() {
        let settings = Config.settings
        XCTAssertEqual(settings.count, 0, "Initial settings should be empty but not nil.")
    }
    
    func testInitialLastRefreshDate() {
        let date = Config.lastRefreshDate
        XCTAssertNil(date, "Initial last refresh date should be nil.")
    }
    
    // MARK: - Test API
    
    func testLaunchWithoutParameters() {
        Config.launch()
        
        testInitialSettings()
        testInitialLastRefreshDate()
    }
    
    func testLaunchWithLocalConfig() {
        Config.launch(localConfig: localConfig)

        let settings = Config.settings
        XCTAssertEqual(settings.count, 4, "Initial settings should contain given local config.")
        
        let date = Config.lastRefreshDate
        XCTAssertNotNil(date, "Initial last refresh date should not be nil.")
        
        testAccessorsWithLocalConfigButWithoutDefaultValues()
        testAccessorsWithLocalConfigAndDefaultValues()
    }
    
    func testRefreshWithoutRemoteURL() {
        let message = "Should return NoRemoteURL error whene remoteURL is not set."
        performAsyncRefreshWithURL(nil, errorCode: Config.Error.NoRemoteURL, message: message)
    }
    
    func testRefreshWithBadRemoteURL() {
        let url = NSURL(string: "http://appculture.com/not-existing-config.json")
        let message = "Should return BadResponseCode error when response is not 200 OK."
        performAsyncRefreshWithURL(url, errorCode: Config.Error.BadResponseCode, message: message)
    }
    
    func testRefreshWithRemoteConfigEmptyData() {
        let url = NSURL(string: "http://private-83024-acconfig.apiary-mock.com/acconfig/empty-config")
        let message = "Should return InvalidData error when response data is empty."
        performAsyncRefreshWithURL(url, errorCode: Config.Error.InvalidData, message: message)
    }
    
    func testRefreshWithRemoteConfigInvalidData() {
        let url = NSURL(string: "http://private-83024-acconfig.apiary-mock.com/acconfig/invalid-config")
        let message = "Should return InvalidData error when response data is not valid JSON."
        performAsyncRefreshWithURL(url, errorCode: Config.Error.InvalidData, message: message)
    }
    
    func testRefreshWithRemoteConfig() {
        let url = NSURL(string: "http://private-83024-acconfig.apiary-mock.com/acconfig/config")
        performAsyncRefreshWithURL(url, errorCode: Config.Error.NoRemoteURL, message: nil)
    }
    
    func performAsyncRefreshWithURL(url: NSURL?, errorCode: Config.Error, message: String?) {
        let asyncExpectation = expectationWithDescription("refresh-\(url?.lastPathComponent)")
        
        if let remoteURL = url {
            Config.launch(remoteConfigURL: remoteURL)
        }
        
        Config.refresh { (block) in
            do {
                let _ = try block()
                self.checkAccessorsWithRemoteConfigButWithoutDefaultValues()
                asyncExpectation.fulfill()
            } catch {
                XCTAssertEqual("\(error)", "\(errorCode)", "\(message)")
                asyncExpectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    // MARK: - Test Accessors
    
    func checkAccessorsWithRemoteConfigButWithoutDefaultValues() {
        let bool = ConfigBool("RemoteBool")
        XCTAssertEqual(bool, false, "Should default to value in remote config.")
        
        let int = ConfigInt("RemoteInt")
        XCTAssertEqual(int, 21, "Should default to value in remote config.")
        
        let double = ConfigDouble("RemoteDouble")
        XCTAssertEqual(double, 0.8, "Should default to value in remote config.")
        
        let string = ConfigString("RemoteString")
        XCTAssertEqual(string, "Remote", "Should default to value in remote config.")
    }
    
    func testAccessorsWithoutLocalConfigAndDefaultValues() {
        let bool = ConfigBool("BoolKey")
        XCTAssertEqual(bool, false, "Should default to false.")
        
        let int = ConfigInt("IntKey")
        XCTAssertEqual(int, 0, "Should default to 0.")
        
        let double = ConfigDouble("DoubleKey")
        XCTAssertEqual(double, 0.0, "Should default to 0.0.")
        
        let string = ConfigString("StringKey")
        XCTAssertEqual(string, String(), "Should default to empty string.")
    }
    
    func testAccessorsWithoutLocalConfigButWithDefaultValues() {
        let bool = ConfigBool("BoolKey", true)
        XCTAssertEqual(bool, true, "Should default to given value.")
        
        let int = ConfigInt("IntKey", 21)
        XCTAssertEqual(int, 21, "Should default to given value.")
        
        let double = ConfigDouble("DoubleKey", 0.8)
        XCTAssertEqual(double, 0.8, "Should default to given value.")
        
        let string = ConfigString("StringKey", "Hello")
        XCTAssertEqual(string, "Hello", "Should default to given value.")
    }
    
    func testAccessorsWithLocalConfigButWithoutDefaultValues() {
        Config.launch(localConfig: localConfig)
        
        let bool = ConfigBool("LocalBool")
        XCTAssertEqual(bool, true, "Should default to value in local config.")
        
        let int = ConfigInt("LocalInt")
        XCTAssertEqual(int, 8, "Should default to value in local config.")
        
        let double = ConfigDouble("LocalDouble")
        XCTAssertEqual(double, 0.21, "Should default to value in local config.")
        
        let string = ConfigString("LocalString")
        XCTAssertEqual(string, "Local", "Should default to value in local config.")
    }
    
    func testAccessorsWithLocalConfigAndDefaultValues() {
        Config.launch(localConfig: localConfig)
        
        let bool = ConfigBool("LocalBool", false)
        XCTAssertEqual(bool, true, "Should default to value in local config.")
        
        let int = ConfigInt("LocalInt", 123)
        XCTAssertEqual(int, 8, "Should default to value in local config.")
        
        let double = ConfigDouble("LocalDouble", 12.3)
        XCTAssertEqual(double, 0.21, "Should default to value in local config.")
        
        let string = ConfigString("LocalString", "Default")
        XCTAssertEqual(string, "Local", "Should default to value in local config.")
    }
    
}
