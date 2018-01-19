//
//  ReduxReducer.swift
//  HMRequestFramework-FullDemo
//
//  Created by Hai Pham on 20/1/18.
//  Copyright © 2018 Holmusk. All rights reserved.
//

import HMReactiveRedux

public final class ReduxReducer {
    public static func reducer(_ state: HMState, _ action: HMActionType) -> HMState {
        return HMGeneralReduxReducer.generalReducer(state, action)
    }
}
