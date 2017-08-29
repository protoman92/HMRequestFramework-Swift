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
    
    @IBOutlet private weak var segmentedCtrl: UISegmentedControl!
    @IBOutlet private weak var insertBtn: UIButton!
    @IBOutlet private weak var updateRandomBtn: UIButton!
    @IBOutlet private weak var deleteRandomBtn: UIButton!
    @IBOutlet private weak var deleteAllBtn: UIButton!
    @IBOutlet private weak var frcTableView: UITableView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    private let dummyCount = 10
    private let dateMilestone = Date.random() ?? Date()
    
    private lazy var settings: [(NSPredicate, [NSSortDescriptor])] = [
        (NSPredicate(value: true),
         [NSSortDescriptor(key: "date", ascending: true)]),
        
        (NSPredicate(format: "%K > %@", "date", self.dateMilestone as NSDate),
         [NSSortDescriptor(key: "int64", ascending: false)]),
        
        (NSPredicate(format: "%K < %@", "date", self.dateMilestone as NSDate), [])
    ]
    
    private var contentHeight: NSLayoutConstraint? {
        return view?.constraints.first(where: {$0.identifier == "contentHeight"})
    }
    
    private var data: Variable<[Section]> = Variable([])
    private var currentSegment: Variable<Int> = Variable(-1)
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var dbProcessor: HMCDRequestProcessor?
    private var dateFormatter = DateFormatter()
    
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
            let deleteAllBtn = self.deleteAllBtn,
            let segmentedCtrl = self.segmentedCtrl
        else {
            return
        }
        
        let disposeBag = self.disposeBag
        let dummyCount = self.dummyCount
        let settings = self.settings
        let dbProcessor = DemoSingleton.dbProcessor
        self.dbProcessor = dbProcessor
        dateFormatter.dateFormat = "dd/MMMM/yyyy hh:mm:ss a"
        
        /// Segmented control setup.
        
        segmentedCtrl.removeAllSegments()
        
        for (index, (predicate, _)) in settings.enumerated() {
            segmentedCtrl.insertSegment(withTitle: predicate.description,
                                        at: index,
                                        animated: true)
        }
        
        segmentedCtrl.addTarget(self,
                                action: #selector(self.segmentChanged(_:)),
                                for: .valueChanged)

        currentSegment.asObservable()
            .filter({$0 > -1})
            .map(settings.element)
            .map({try $0.asTry().getOrThrow()})
            .flatMapLatest({
                [weak self] setting -> Observable<Try<HMCDEvent<Dummy1>>> in
                let predicate = setting.0
                let sorts = setting.1
                
                return self?.dbProcessor?.streamDBEvents(Dummy1.self, {
                    Observable.just($0.cloneBuilder()
                        .with(predicate: predicate)
                        .with(sortDescriptors: sorts)
                        .with(frcSectionName: "dummyHeader")
                        .with(frcCacheName: "FRC_Dummy1")
                        .build())
                }) ?? .empty()
            })
            .map({try $0.getOrThrow()})
            .flatMap({(event) -> Observable<DBChange<Dummy1>> in
                switch event {
                case .initialize(let change): return Observable.just(change)
                case .didChange(let change): return Observable.just(change)
                default: return .empty()
                }
            })
            .map({$0.sections.map({$0.animated()})})
            .catchErrorJustReturn([])
            .bind(to: data)
            .disposed(by: disposeBag)
        
        /// Table View setup.
        
        let dataSource = setupDataSource()
        frcTableView.setEditing(true, animated: true)
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
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.deleteInMemory($0)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0)
            })
            .map(toVoid)
            .catchErrorJustReturn(())
            .subscribe()
            .disposed(by: disposeBag)
        
        data.asObservable()
            .bind(to: frcTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        /// Button setup.
        
        insertBtn.setTitle("Insert \(dummyCount) items", for: .normal)
        
        insertBtn.rx.tap
            .map({_ in (0..<dummyCount).map({_ in Dummy1()})})
            .map(Try.success)
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.saveToMemory($0)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0)
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
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.upsertInMemory($0)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0)
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
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.deleteInMemory($0)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        deleteAllBtn.rx.tap
            .map(Try.success)
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.deleteAllInMemory($0, Dummy1.self)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0)
            })
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    func segmentChanged(_ control: UISegmentedControl) {
        currentSegment.value = control.selectedSegmentIndex
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
