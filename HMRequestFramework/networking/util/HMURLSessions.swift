//
//  HMURLSession.swift
//  HMRequestFramework
//
//  Created by Hai Pham on 18/8/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift

public extension Reactive where Base == URLSession {
    private func uploadCompletionBlock<O>(_ data: Data?,
                                          _ response: URLResponse?,
                                          _ error: Error?,
                                          _ obs: O) where
        O: ObserverType, O.E == Data
    {
        if let error = error {
            obs.onError(error)
        } else {
            obs.onNext(data ?? Data(capacity: 0))
            obs.onCompleted()
        }
    }
    
    /// Perform an upload request with some data and bypass URLSession delegate.
    ///
    /// - Parameters:
    ///   - request: A URLRequest instance.
    ///   - data: A Data instance.
    /// - Returns: An Observable instance.
    public func uploadWithCompletion(_ request: URLRequest, _ data: Data)
        -> Observable<Data>
    {
        return Observable<Data>.create({obs in
            let base = self.base
            
            let task = base.uploadTask(with: request, from: data) {
                self.uploadCompletionBlock($0, $1, $2, obs)
            }
            
            task.resume()
            return Disposables.create(with: { task.cancel() })
        })
    }
    
    /// Perform an upload request with some URL and bypass URLSession delegate.
    ///
    /// - Parameters:
    ///   - request: A URLRequest instance.
    ///   - data: A Data instance.
    /// - Returns: An Observable instance.
    public func uploadWithCompletion(_ request: URLRequest, _ url: URL)
        -> Observable<Data>
    {
        return Observable<Data>.create({obs in
            let base = self.base
            
            let task = base.uploadTask(with: request, fromFile: url) {
                self.uploadCompletionBlock($0, $1, $2, obs)
            }
            
            task.resume()
            return Disposables.create(with: { task.cancel() })
        })
    }
}
