//
//  StoreTeardownTests.swift
//  CoreDataStack
//
//  Created by Robert Edwards on 7/10/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

import XCTest

import CoreData

class StoreTeardownTests: TempDirectoryTestCase {

    var stack: CoreDataStack!

    override func setUp() {
        super.setUp()

        let bundle = NSBundle(forClass: CoreDataStackTests.self)
        let expectation = expectationWithDescription("callback")
        CoreDataStack.constructSQLiteStack(withModelName: "TestModel", inBundle: bundle, withStoreURL: tempStoreURL) { result in
            switch result {
            case .Success(let stack):
                self.stack = stack
            case .Failure(let error):
                XCTFail("Error constructing stack: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }


    func testPersistentStoreReset() {
        // Insert some fresh objects
        let worker = stack.newBackgroundWorkerMOC()
        worker.performBlockAndWait() {
            for _ in 0..<100 {
                NSEntityDescription.insertNewObjectForEntityForName("Author", inManagedObjectContext: worker)
            }
        }

        // Save just the worker context synchronously
        try! worker.saveContextAndWait()

        // The reset function will wait for all changes to bubble up before removing the store file.
        let expectation = expectationWithDescription("callback")
        stack.resetSQLiteStore() { result in
            switch result {
            case .Success:
                break
            case .Failure(let error):
                print(error)
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
