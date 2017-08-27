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

extension CDDummy1 {
    public func dummyHeader() -> String {
        return "Dummy header"
    }
}

// Please do not use forced unwraps in production apps.
public final class FRCController: UIViewController {
    typealias Section = HMCDAnimatableSection<Dummy1>
    typealias DataSource = TableViewSectionedDataSource<Section>
    typealias RxDataSource = RxTableViewSectionedAnimatedDataSource<Section>
    
    @IBOutlet weak var insertBtn: UIButton!
    @IBOutlet weak var updateRandomBtn: UIButton!
    @IBOutlet weak var deleteRandomBtn: UIButton!
    @IBOutlet weak var deleteAllBtn: UIButton!
    @IBOutlet weak var frcTableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let dummyCount = 10
    
    var contentHeight: NSLayoutConstraint? {
        return view?.constraints.first(where: {$0.identifier == "contentHeight"})
    }
    
    var data: Variable<[Section]> = Variable([])
    let disposeBag: DisposeBag = DisposeBag()
    
    var cdManager: HMCDManager?
    var dbProcessor: HMCDRequestProcessor?
    var dateFormatter = DateFormatter()
    
    deinit {
        print("Deinit \(self)")
    }
 
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let frcTableView = self.frcTableView,
            let insertBtn = self.insertBtn,
            let updateRandomBtn = self.updateRandomBtn,
            let deleteRandomBtn = self.deleteRandomBtn,
            let deleteAllBtn = self.deleteAllBtn
        else {
            return
        }
                
        let dummyCount = self.dummyCount
        let cdManager = Singleton.coreDataManager(.SQLite)
        let dbProcessor = Singleton.dbProcessor(cdManager)
        
        self.cdManager = cdManager
        self.dbProcessor = dbProcessor
        dateFormatter.dateFormat = "dd/MMMM/yyyy hh:mm:ss a"
        
        insertBtn.setTitle("Insert \(dummyCount) items", for: .normal)
        
        insertBtn.rx.tap
            .map({_ in (0..<dummyCount).map({_ in Dummy1()})})
            .map(Try.success)
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.saveToMemory(prev)
                } else {
                    return Observable.empty()
                }
            })
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.persistToDB(prev)
                } else {
                    return Observable.empty()
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        updateRandomBtn.rx.tap
            .withLatestFrom(data.asObservable())
            .filter({$0.isNotEmpty})
            .map({$0.randomElement()?.items.randomElement()})
            .map({$0.asTry()})
            .map({$0.map({Dummy1().cloneBuilder().with(id: $0.id).build()})})
            .map({$0.map({[$0]})})
            .flatMap({[weak self] prev -> Observable<Try<[HMCDResult]>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.upsertInMemory(prev, {
                        Observable.just($0.cloneBuilder()
                            .with(vcStrategy: .overwrite)
                            .build())
                    })
                } else {
                    return Observable.empty()
                }
            })
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.persistToDB(prev)
                } else {
                    return Observable.empty()
                }
            })
            .map(toVoid)
            .subscribe()
            .disposed(by: disposeBag)
        
        deleteRandomBtn.rx.tap
            .withLatestFrom(data.asObservable())
            .filter({$0.isNotEmpty})
            .map({$0.randomElement()?.items.randomElement()})
            .map({$0.asTry()})
            .map({$0.map({[$0]})})
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.deleteInMemory(prev)
                } else {
                    return Observable.empty()
                }
            })
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.persistToDB(prev)
                } else {
                    return Observable.empty()
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        deleteAllBtn.rx.tap
            .map(Try.success)
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.deleteAllInMemory(prev, Dummy1.self)
                } else {
                    return Observable.empty()
                }
            })
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.persistToDB(prev)
                } else {
                    return Observable.empty()
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        frcTableView.rx.setDelegate(self).disposed(by: disposeBag)
        
        frcTableView.rx.observe(CGSize.self, "contentSize")
            .distinctUntilChanged({$0.0 == $0.1})
            .map({$0.asTry()})
            .map({try $0.getOrThrow()})
            .doOnNext({[weak self] in
                if let `self` = self {
                    self.contentSizeChanged($0, self)
                }
            })
            .map(toVoid)
            .catchErrorJustReturn(())
            .subscribe()
            .disposed(by: disposeBag)
        
        frcTableView.rx.itemDeleted
            .map({[weak self] in self?.data.value
                .element(at: $0.section)?.items
                .element(at: $0.row)})
            .map({$0.asTry()})
            .map({$0.map({[$0]})})
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.deleteInMemory(prev)
                } else {
                    return Observable.empty()
                }
            })
            .flatMap({[weak self] prev -> Observable<Try<Void>> in
                if let `self` = self, let dbProcessor = self.dbProcessor {
                    return dbProcessor.persistToDB(prev)
                } else {
                    return Observable.empty()
                }
            })
            .map(toVoid)
            .catchErrorJustReturn(())
            .subscribe()
            .disposed(by: disposeBag)
        
        let dbEventStream = dbProcessor
            .streamDBEvents(Dummy1.self, {
                Observable.just($0.cloneBuilder()
                    .with(frcSectionName: "dummyHeader")
                    .add(ascendingSortWithKey: "date")
                    .build())
            })
            .map({try $0.getOrThrow()})
            .flatMap({(event) -> Observable<DBChange<Dummy1>> in
                switch event {
                case .didChange(let change): return .just(change)
                default: return .empty()
                }
            })
            .map({$0.sections.map({$0.animated()})})
            .catchErrorJustReturn([])
            .shareReplay(1)
        
        let dataSource = setupDataSource()
        
        dbEventStream
            .bind(to: data)
            .disposed(by: disposeBag)
        
        dbEventStream
            .bind(to: frcTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        frcTableView?.setEditing(true, animated: true)
    }
    
    func contentSizeChanged(_ ctSize: CGSize, _ vc: FRCController) {
        guard
            let view = vc.view,
            let contentHeight = vc.contentHeight,
            let frcTableView = vc.frcTableView,
            let scrollView = vc.scrollView
        else {
            return
        }
    
        let vFrame = view.frame
        let frcFrame = frcTableView.frame
        let frcY = frcFrame.minY
        let ctHeight = ctSize.height + frcY
        let scrollHeight = Swift.max(vFrame.height, ctHeight)
        let newMultiplier = scrollHeight / vFrame.height
        scrollView.contentSize.height = scrollHeight
        
        let newConstraint = NSLayoutConstraint(
            item: contentHeight.firstItem,
            attribute: contentHeight.firstAttribute,
            relatedBy: contentHeight.relation,
            toItem: contentHeight.secondItem,
            attribute: contentHeight.secondAttribute,
            multiplier: newMultiplier,
            constant: contentHeight.constant)
        
        newConstraint.identifier = contentHeight.identifier
        
        UIView.animate(withDuration: 0.1) {
            view.removeConstraint(contentHeight)
            view.addConstraint(newConstraint)
        }
    }
    
    func setupDataSource() -> RxDataSource {
        let source = RxDataSource()
        
        source.configureCell = {[weak self] in
            if let `self` = self {
                return self.configureCell($0.0, $0.1, $0.2, $0.3)
            } else {
                return UITableViewCell()
            }
        }
        
        source.canEditRowAtIndexPath = {_ in true}
        source.canMoveRowAtIndexPath = {_ in true}
        source.titleForHeaderInSection = {$0.0[$0.1].name}
        return source
    }
    
    func configureCell(_ source: DataSource,
                       _ tableView: UITableView,
                       _ indexPath: IndexPath,
                       _ object: Dummy1) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FRCCell",
                for: indexPath) as? FRCCell,
            let titleLbl = cell.titleLbl,
            let date = object.date
        else {
            return UITableViewCell()
        }
        
        titleLbl.text = dateFormatter.string(from: date)
        return cell
    }
    
    // This is not needed yet. So far RxDataSources seems to be working well
    // enough.
    func onStreamEventReceived(_ event: HMCDEvent<Dummy1>, _ vc: FRCController) {
        let tableView = vc.frcTableView!
        
        switch event {
        case .willChange:
            tableView.beginUpdates()
            
        case .didChange:
            tableView.endUpdates()
            
        case .insert(let change):
            if let newIndex = change.newIndex {
                tableView.insertRows(at: [newIndex], with: .fade)
            }
            
        case .delete(let change):
            if let oldIndex = change.oldIndex {
                tableView.deleteRows(at: [oldIndex], with: .fade)
            }
            
        case .move(let change):
            onStreamEventReceived(.delete(change), vc)
            onStreamEventReceived(.insert(change), vc)
            
        case .insertSection(_, let sectionIndex):
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            
        case .deleteSection(_, let sectionIndex):
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            
        case .updateSection(_, let sectionIndex):
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .fade)
            
        default:
            break
        }
    }
}

extension FRCController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}

public final class FRCCell: UITableViewCell {
    @IBOutlet weak var titleLbl: UILabel!
}
