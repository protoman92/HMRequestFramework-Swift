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
import SwiftUIUtilities

extension CDDummy1 {
    public func dummyHeader() -> String {
        return "Dummy header"
    }
}

extension HMCDSectionType {
    public var sectionName: String {
        return name
    }
}

extension AnimatableSectionModel where Section == String {
    public var sectionName: String {
        return model
    }
}

/// Please do not use forced unwraps in production apps.
///
/// This is a very poor implementation of a view controller. Its only purpose
/// is to showcase some techniques supported by the request framework, and under
/// no circumstances should it be treated as sample code.
public final class FRCController: UIViewController {
    typealias Section = HMCDAnimatableSection<Dummy1>
    typealias DataSource = TableViewSectionedDataSource<Section>
    typealias RxDataSource = RxTableViewSectionedAnimatedDataSource<Section>
    
    @IBOutlet private weak var insertBtn: UIButton!
    @IBOutlet private weak var updateRandomBtn: UIButton!
    @IBOutlet private weak var deleteRandomBtn: UIButton!
    @IBOutlet private weak var deleteAllBtn: UIButton!
    @IBOutlet private weak var frcTableView: UITableView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    private let dummyCount = 10
    private let dateMilestone = Date.random() ?? Date()
    
    private var contentHeight: NSLayoutConstraint? {
        return view?.constraints.first(where: {$0.identifier == "contentHeight"})
    }
    
    private var data: Variable<[Section]> = Variable([])
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
            let scrollView = self.scrollView
        else {
            return
        }
        
        let disposeBag = self.disposeBag
        let dummyCount = self.dummyCount
        let dbProcessor = DemoSingleton.dbProcessor
        let qos: DispatchQoS.QoSClass = .userInteractive
        self.dbProcessor = dbProcessor
        dateFormatter.dateFormat = "dd/MMM/yyyy hh:mm:ss a"
        
        /// Scroll view setup
        
        let pageObs = Observable<HMCursorDirection>.merge(
            scrollView.rx.didOverscroll(100, .up, .down)
                .debounce(0.6, scheduler: MainScheduler.instance)
                .map({$0.rawValue})
                .map({HMCursorDirection(from: $0)})
                .startWith(.remain)
        )
        
        /// Table View setup.
        
        let dataSource = setupDataSource()
        frcTableView.setEditing(true, animated: true)
        frcTableView.rx.setDelegate(self).disposed(by: disposeBag)
        
        frcTableView.rx.contentSize
            .doOnNext({[weak self] cs in self.map({$0.contentSizeChanged(cs, $0)})})
            .map(toVoid)
            .subscribe()
            .disposed(by: disposeBag)
        
        frcTableView.rx.itemDeleted
            .map({[weak self] in self?.data.value
                .element(at: $0.section)?.items
                .element(at: $0.row)})
            .map({$0.asTry()})
            .map({$0.map({[$0]})})
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.deleteInMemory($0, qos)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0, qos)
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
                self?.dbProcessor?.saveToMemory($0, qos)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0, qos)
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
                self?.dbProcessor?.upsertInMemory($0, qos)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0, qos)
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
                self?.dbProcessor?.deleteInMemory($0, qos)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0, qos)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        deleteAllBtn.rx.tap
            .map(Try.success)
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.deleteAllInMemory($0, Dummy1.self, qos)
            })
            .flatMapNonNilOrEmpty({[weak self] in
                self?.dbProcessor?.persistToDB($0, qos)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        /// Data source setup
                
        dbProcessor
            .streamPaginatedDBEvents(
                Dummy1.self, pageObs,
                HMCDPagination.builder()
                    .with(fetchLimit: 5)
                    .with(fetchOffset: 0)
                    .with(paginationMode: .fixedPageCount)
                    .build(), qos,
                {
                    Observable.just($0.cloneBuilder()
                        .with(predicate: NSPredicate(value: true))
                        .add(ascendingSortWithKey: "date")
                        .with(frcSectionName: "date")
                        .with(frcCacheName: "FRC_Dummy1")
                        .build())
                }
            )
            .flatMap(HMCDEvents.didLoadAnimatableSections)
            .bind(to: data)
            .disposed(by: disposeBag)
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
            item: contentHeight.firstItem!,
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
                return self.configureCell($0, $1, $2, $3)
            } else {
                return UITableViewCell()
            }
        }
        
        source.canEditRowAtIndexPath = {(_, _) in true}
        source.canMoveRowAtIndexPath = {(_, _) in true}
        source.titleForHeaderInSection = {$0[$1].sectionName}
        return source
    }
    
    func configureCell(_ source: DataSource,
                       _ tableView: UITableView,
                       _ indexPath: IndexPath,
                       _ object: Section.Item) -> UITableViewCell {
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
