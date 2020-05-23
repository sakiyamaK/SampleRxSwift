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

  //ViewModelの書き方のひとつで、input,outputを明確に分けた書き方
  private let viewModel = RxGithubSearchMVVMViewModel()
  private lazy var input: RxGithubSearchMVVMViewModelInput = viewModel
  private lazy var output: RxGithubSearchMVVMViewModelOutput = viewModel

  //viewDidLoadで必要なストリームを決める
  override func viewDidLoad() {
    super.viewDidLoad()

    //inputとoutputのストリームを決める
    bindInputStream()
    bindOutputStream()
  }

  //viewModelの中に流すストリーム
  private func bindInputStream() {
    //文字列のストリーム (1)
    //0.5sec以上,変化している,nilでない,文字数0以上
    //であればテキストをストリームに流す
    let searchTextObservable = urlTextField.rx.text
      .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
      .distinctUntilChanged().filterNil()

    //ソートのストリーム (2)
    //初回読み込み時または変化があれば
    //sortTypeSegmentedControlのindexをストリームに流す
    let sortTypeObservable = Observable.merge(
      Observable.just(sortTypeSegmentedControl.selectedSegmentIndex),
      sortTypeSegmentedControl.rx.controlEvent(.valueChanged).map { self.sortTypeSegmentedControl.selectedSegmentIndex }
    ).map { $0 == 0 }

    //inputのプロパティと繋げる (bindはそのまま値をストリームに流す
    searchTextObservable.bind(to: input.searchTextObserver).disposed(by: disposeBag)
    sortTypeObservable.bind(to: input.sortTypeObserver).disposed(by: disposeBag)
  }

  //viewModelからくるストリーム
  private func bindOutputStream() {
    //outputの「modelsに変化があったよ」というストリームが流れてきたらテーブルを更新
    output.changeModelsObservable.subscribeOn(MainScheduler.instance).subscribe(onNext: {
      self.tableView.reloadData()
    }, onError: { error in
      print(error.localizedDescription)
    }).disposed(by: disposeBag)
  }
}

extension RxGithubSearchMVVMViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //outputの中にmodelsがある
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
