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

import RxOptional

final class RxGithubSearchNoMVVMViewController: UIViewController {
  
  @IBOutlet private weak var urlTextField: UITextField!
  @IBOutlet private weak var tableView: UITableView! {
    didSet {
      let cell = UINib(nibName: "GithubTableViewCell", bundle: nil)
      tableView.register(cell, forCellReuseIdentifier: "Cell")
    }
  }
  @IBOutlet private weak var sortTypeSegmentedControl: UISegmentedControl!

  var responseData: [GithubModel] = []

  //viewDidLoadで必要なストリームを決める
  override func viewDidLoad() {
    super.viewDidLoad()

    //----------------
    //文字列のストリーム (1)
    //0.5sec以上,変化している,nilでない,文字数0以上
    //であればテキストをストリームに流す
    let searchTextObservable = urlTextField.rx.text
      .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
      .distinctUntilChanged()
      .filterNil()

    //ソートのストリーム (2)
    //初回読み込み時または変化があれば
    //sortTypeSegmentedControlのindexをストリームに流す
    let sortTypeObservable = Observable.merge(
      Observable.just(sortTypeSegmentedControl.selectedSegmentIndex),
      sortTypeSegmentedControl.rx.controlEvent(.valueChanged).map { self.sortTypeSegmentedControl.selectedSegmentIndex }
    ).map { $0 == 0 }

    //(1),(2)を合成してストリームに値がきたらAPIを叩いてテーブルをリロード
    let getAPIObservable = Observable.combineLatest(
      searchTextObservable,
      sortTypeObservable
    ).flatMapLatest({ (searchWord, sortType) -> Observable<[GithubModel]> in
      GithubAPI.shared.rx.get(searchWord: searchWord, isDesc: sortType)
    })
    //-------------------

    //------------------
    //購買する
    getAPIObservable
      .subscribeOn(MainScheduler.instance)
      .subscribe(onNext: {[weak self] (models) in
        self?.responseData = models
        self?.tableView.reloadData()
        }, onError: { error in
          print(error.localizedDescription)
        }).disposed(by: rx.disposeBag)
    //------------------

    //この書き方だとUITableViewDataSourceすらいらなくなるがtableviewの警告が出た
//    getAPIObservable.subscribeOn(MainScheduler.instance)
//      .bind(to: self.tableView.rx.items(cellIdentifier: "Cell", cellType: GithubTableViewCell.self)){(row, element, cell) in
//          cell.configure(githubModel: element)
//        }.disposed(by: disposeBag)
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
