//
//  XCTestCase+Helpers.swift
//  2HQTests
//
//  Created by Nikola Ticojevic on 12. 1. 2026..
//

import XCTest
@testable import _HQ

extension XCTestCase {
    func waitForAsyncOperation(timeout: TimeInterval = 1.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
}
