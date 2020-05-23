//
//  RxGithubSearchMVVMViewModel.swift
//  SampleRxSwift
//
//  Created by sakiyamaK on 2020/05/23.
//  Copyright © 2020 sakiyamaK. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import NSObject_Rx

//ViewModelの入力に関するprotocol
protocol RxGithubSearchMVVMViewModelInput {
  var searchTextObserver: AnyObserver<String> { get }
  var sortTypeObserver: AnyObserver<Bool> { get }
}

//ViewModelの出力に関するprotocol
protocol RxGithubSearchMVVMViewModelOutput {
  var changeModelsObservable: Observable<Void> { get }
  var models: [GithubModel] { get }
}

//ViewModelはInputとOutputのprotocolに準拠する
final class RxGithubSearchMVVMViewModel: RxGithubSearchMVVMViewModelInput, RxGithubSearchMVVMViewModelOutput, HasDisposeBag {

  /*inputについての記述*/
  //入力側の定型文的な書き方
  private let _searchText = PublishRelay<String>()
  lazy var searchTextObserver: AnyObserver<String> = .init(eventHandler: { (event) in
    guard let e = event.element else { return }
    self._searchText.accept(e)
  })

  //入力側の定型文的な書き方
  private let _sortType = PublishRelay<Bool>()
  lazy var sortTypeObserver: AnyObserver<Bool> = .init(eventHandler: { (event) in
    guard let e = event.element else { return }
    self._sortType.accept(e)
  })

  /*outputについての記述*/
  //出力側の定型文的な書き方
  private let _changeModelsObservable = PublishRelay<Void>()
  lazy var changeModelsObservable = _changeModelsObservable.asObservable()
  //最後に取得したデータ
  private(set) var models: [GithubModel] = []

  //初期化時にストリームを決める
  init() {
    //入力のを合成してストリームに値がきたらAPIを叩いて
    //出力に値を保存して,出力にストリームを流す
    Observable.combineLatest(
      _searchText,
      _sortType
    ).flatMapLatest({ (searchWord, sortType) -> Observable<[GithubModel]> in
      GithubAPI.shared.rx.get(searchWord: searchWord, isDesc: sortType)
    }).map {[weak self] (models) -> Void in
      //最後に得たデータを保存
      self?.models = models
      //値が更新したことを告げるためだけのストリームを流すのでVoidにする
      return
    }.bind(to: _changeModelsObservable).disposed(by: disposeBag)
  }
}
