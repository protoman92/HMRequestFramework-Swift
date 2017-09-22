//
//  SSEController.swift
//  HMRequestFramework-Demo
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMEventSourceManager
import HMRequestFramework
import ReachabilitySwift
import RxSwift
import SwiftUtilities

public final class SSEController: UIViewController {
    @IBOutlet fileprivate weak var textView: UITextView!
    
    fileprivate let disposeBag = DisposeBag()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let textView = self.textView else { return }
        
        let username = "fe8b0af5-1b50-467d-ac0b-b29d2d30136b"
        let password = "ae10ff39ca41dgf0a8"
        let authString = "\(username):\(password)"
        let authData = authString.data(using: String.Encoding.utf8)
        let base64String = authData!.base64EncodedString(options: [])
        let authToken = "Basic \(base64String)"
        
        let sseManager = HMSSEManager.builder()
            .with(userDefaults: UserDefaults.standard)
            .with(networkChecker: Reachability())
            .build()
        
        let addBaseURLKey = "ADD-BASE-URL"
        let addAuthTokenKey = "ADD-AUTH-TOKEN"
        let logRequestKey = "LOG-REQUEST"
        
        let middlewareManager = HMFilterMiddlewareManager<HMNetworkRequest>
            .builder()
            .add(transform: {
                Observable.just($0.cloneBuilder()
                    .with(baseUrl: "http://127.0.0.1:8080")
                    .build())
            }, forKey: addBaseURLKey)
            .add(transform: {
                Observable.just($0.cloneBuilder()
                    .add(header: authToken, forKey: "Authorization")
                    .build())
            }, forKey: addAuthTokenKey)
            .add(sideEffect: {print($0)}, forKey: logRequestKey)
            .build()
        
        let networkHandler = HMNetworkRequestHandler.builder()
            .with(sseManager: sseManager)
            .with(rqmManager: middlewareManager)
            .build()

        let request = HMNetworkRequest.builder()
            .with(operation: .sse)
            .with(urlString: "sse")
            .with(retryDelay: 3)
            .add(mwFilter: HMMiddlewareFilters.includingFilters(
                addAuthTokenKey,
                addBaseURLKey,
                logRequestKey
            ))
            .build()
        
        let previous = Try.success(())
        let generator = HMRequestGenerators.forceGn(request, Void.self)
        
        networkHandler.executeSSE(previous, generator)
            .mapNonNilOrEmpty({$0.value})
            .map(HMSSEvents.eventData)
            .flattenSequence()
            .doOnNext({[weak textView] in
                if let textView = textView {
                    let description = $0.description
                    let previousText = textView.text ?? ""
                    let currentText = "\(previousText)\(description)\n\n"
                    textView.text = currentText
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
    }
}
