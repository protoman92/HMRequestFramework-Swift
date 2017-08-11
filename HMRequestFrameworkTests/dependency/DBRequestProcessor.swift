//
//  DBRequestProcessor.swift
//  HMRequestFrameworkTests
//
//  Created by Hai Pham on 21/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import CoreData
import RxSwift
import SwiftUtilities
@testable import HMRequestFramework

public struct DBRequestProcessor {
    public let processor: HMCDRequestProcessor
    
    public init(processor: HMCDRequestProcessor) {
        self.processor = processor
    }
}
