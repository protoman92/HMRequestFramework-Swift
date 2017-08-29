//
//  HMCDPaginationMode.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 8/30/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Specify the pagination mode. Each mode shall determine how pagination numbers
/// are incremented.
///
/// - fixedPageCount: Fixed fetch limit, variable fetch offset.
/// - variablePageCount: Variable fetch limit, fixed fetch offset.
public enum HMCDPaginationMode {
    case fixedPageCount
    case variablePageCount
}
