//
//  HMCDSections.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 9/1/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Utility class for HMCDSection.
public final class HMCDSections {
    
    /// Get the object for a particular index path from a Sequence of sections.
    ///
    /// - Parameters:
    ///   - sections: A Sequence of HMCDSectionType.
    ///   - indexPath: An IndexPath instance.
    /// - Returns: A ST.V instance.
    public func object<ST,S>(_ sections: S, _ indexPath: IndexPath) -> ST.V? where
        ST: HMCDSectionType,
        S: Sequence,
        S.Iterator.Element == ST
    {
        let sections = sections.map({$0})
        let section = indexPath.section
        let row = indexPath.row
        return sections.element(at: section)?.objects.element(at: row)
    }
}
