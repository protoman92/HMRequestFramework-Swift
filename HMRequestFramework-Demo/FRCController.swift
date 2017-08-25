//
//  FRCController.swift
//  HMRequestFramework-Demo
//
//  Created by Hai Pham on 8/25/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import UIKit
import HMRequestFramework
import RxDataSources
import RxSwift
import SwiftUtilities

public final class FRCController: UIViewController {
    @IBOutlet weak var insertBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var frcTbv: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var cdManager: HMCDManager!
    var dbProcessor: HMCDRequestProcessor!
    var disposeBag: DisposeBag!
    
    deinit {
        print("Deinit \(self)")
    }
 
    override public func viewDidLoad() {
        super.viewDidLoad()
        let frcTbv = self.frcTbv!
        cdManager = Singleton.coreDataManager(.InMemory)
        dbProcessor = Singleton.dbProcessor(cdManager!)
        disposeBag = DisposeBag()

        let dbStream = dbProcessor.streamDBEvents(Dummy1.self).share()
        
        insertBtn.rx.controlEvent(.touchDown)
            .map({_ in (0..<1000).map({_ in Dummy1()})})
            .map(Try.success)
            .flatMap({[weak self] in
                self?.dbProcessor.saveToMemory($0) ?? .just(Try.success(()))
            })
            .flatMap({[weak self] in
                self?.dbProcessor.persistToDB($0) ?? .just(Try.success(()))
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        dbStream.map({try $0.getOrThrow()})
            .doOnNext({[weak self] in
                if let `self` = self {
                    self.onStreamEventReceived($0, self)
                }
            })
            .map(toVoid)
            .catchErrorJustReturn(())
            .subscribe()
            .disposed(by: disposeBag)
        
        let dataSource = RxTableViewSectionedReloadDataSource<Any>()
        
        dbStream.map({try $0.getOrThrow()})
            .flatMap({(event) -> Observable<[Dummy1]> in
                switch event {
                case .willChange(let objects):
                    return .just(objects)
                    
                default:
                    return .empty()
                }
            })
    }
    
    func onStreamEventReceived(_ event: HMCDEvent<Dummy1>, _ vc: FRCController) {
        switch event {
        case .insert(let object, let change):
            break
            
        default:
            break
        }
    }
    
    func configureCell(_ )
}
