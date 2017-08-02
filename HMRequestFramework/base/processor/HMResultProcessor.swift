//
//  HMResultProcessor.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 5/7/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Instead of declaring concrete types when perform requests, we delegate the 
/// processing to an external function. This would decouple responsibilities.
public typealias HMResultProcessor<Val,Res> = (Val) throws -> Observable<Try<Res>>

public typealias HMEQResultProcessor<Val> = HMResultProcessor<Val,Val>

public typealias HMProtocolResultProcessor<Val: HMProtocolConvertibleType> =
    HMResultProcessor<Val,Val.PTCType>
