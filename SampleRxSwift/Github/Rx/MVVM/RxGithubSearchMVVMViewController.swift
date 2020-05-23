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

final class RxGithubSearchMVVMViewController: UIViewController, HasDisposeBag {

  @IBOutlet private weak var urlTextField: UITextField!

  @IBOutlet private weak var tableView: UITableView! {
    didSet {
      let cell = UINib(nibName: "GithubTableViewCell", bundle: nil)
      tableView.register(cell, forCellReuseIdentifier: "Cell")
    }
  }

  @IBOutlet private weak var sortTypeSegmentedControl: UISegmentedControl!

  private let viewModel = RxGithubSearchMVVMViewModel()
  private lazy var input: RxGithubSearchMVVMViewModelInput = viewModel
  private lazy var output: RxGithubSearchMVVMViewModelOutput = viewModel

  override func viewDidLoad() {
    super.viewDidLoad()

    bindInputStream()
    bindOutputStream()
  }

  private func bindInputStream() {
    let searchTextObservable = urlTextField.rx.text
      .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
      .distinctUntilChanged().filterNil().filter { $0.count > 0 }

    let sortTypeObservable = Observable.merge(
      Observable.just(sortTypeSegmentedControl.selectedSegmentIndex),
      sortTypeSegmentedControl.rx.controlEvent(.valueChanged).map { self.sortTypeSegmentedControl.selectedSegmentIndex }
    ).map { $0 == 0 }

    searchTextObservable.bind(to: input.searchTextObserver).disposed(by: disposeBag)
    sortTypeObservable.bind(to: input.sortTypeObserver).disposed(by: disposeBag)
  }

  private func bindOutputStream() {
    output.changeModelsObservable.subscribeOn(MainScheduler.instance).subscribe(onNext: { (_) in
      self.tableView.reloadData()
    }).disposed(by: disposeBag)
  }
}

extension RxGithubSearchMVVMViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return output.models.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard
      let githubModel = output.models[safe: indexPath.item],
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? GithubTableViewCell
      else { return UITableViewCell() }
    cell.configure(githubModel: githubModel)
    return cell
  }
}
