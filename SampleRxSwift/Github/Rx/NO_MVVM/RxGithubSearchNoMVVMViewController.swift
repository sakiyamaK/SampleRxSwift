//
//  File.swift
//  SampleRxSwift
//
//  Created by sakiyamaK on 2020/05/23.
//  Copyright © 2020 sakiyamaK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import RxOptional

final class RxGithubSearchNoMVVMViewController: UIViewController, HasDisposeBag {
  
  @IBOutlet private weak var urlTextField: UITextField!
  @IBOutlet private weak var tableView: UITableView! {
    didSet {
      let cell = UINib(nibName: "GithubTableViewCell", bundle: nil)
      tableView.register(cell, forCellReuseIdentifier: "Cell")
    }
  }
  @IBOutlet private weak var sortTypeSegmentedControl: UISegmentedControl!

  var responseData: [GithubModel] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    let searchTextObservable = urlTextField.rx.text
      .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
      .distinctUntilChanged().filterNil().filter { $0.count > 0 }

    let sortTypeObservable = Observable.merge(
      Observable.just(sortTypeSegmentedControl.selectedSegmentIndex),
      sortTypeSegmentedControl.rx.controlEvent(.valueChanged).map { self.sortTypeSegmentedControl.selectedSegmentIndex }
    ).map { $0 == 0 }

    Observable.combineLatest(
      searchTextObservable,
      sortTypeObservable
    ).subscribe(onNext: { (searchWord, sortType) -> Void in
      GithubAPI.shared.get(searchWord: searchWord, isDesc: sortType, success: {[weak self] (models) in
        self?.responseData = models
        self?.tableView.reloadData()
      }) { (error) in
        guard let _error = error else { return }
        debugPrint(_error)
      }
    }).disposed(by: disposeBag)
  }
}

extension RxGithubSearchNoMVVMViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return responseData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard
      let githubModel = responseData[safe: indexPath.item],
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? GithubTableViewCell
    else { return UITableViewCell() }
    cell.configure(githubModel: githubModel)
    return cell
  }
}
