//
//  HMCDResultProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 24/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// The result processors below provide coupling between NSManagedObject subtype
/// and the specific data type we are trying to get.

public typealias HMCDTypedResultProcessor<Res: HMCDParsableType> =
    HMResultProcessor<Res.CDClass,Res>
