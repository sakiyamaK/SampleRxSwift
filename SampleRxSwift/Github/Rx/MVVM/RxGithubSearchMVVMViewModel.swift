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

protocol RxGithubSearchMVVMViewModelInput {
  var searchTextObserver: AnyObserver<String> { get }
  var sortTypeObserver: AnyObserver<Bool> { get }
}

protocol RxGithubSearchMVVMViewModelOutput {
  var changeModelsObservable: Observable<Void> { get }
  var models: [GithubModel] { get }
}


final class RxGithubSearchMVVMViewModel: RxGithubSearchMVVMViewModelInput, RxGithubSearchMVVMViewModelOutput, HasDisposeBag {

  private let _searchText = PublishRelay<String>()
  lazy var searchTextObserver: AnyObserver<String> = .init(eventHandler: { (event) in
    guard let e = event.element else { return }
    self._searchText.accept(e)
  })

  private let _sortType = PublishRelay<Bool>()
  lazy var sortTypeObserver: AnyObserver<Bool> = .init(eventHandler: { (event) in
    guard let e = event.element else { return }
    self._sortType.accept(e)
  })

  private let _changeModelsObservable = PublishRelay<Void>()
  lazy var changeModelsObservable = _changeModelsObservable.asObservable()
  private(set) var models: [GithubModel] = []

  init() {
    Observable.combineLatest(
      _searchText,
      _sortType
    ).subscribe(onNext: { (searchWord, sortType) -> Void in
      GithubAPI.shared.get(searchWord: searchWord, isDesc: sortType, success: {[weak self] (models) in
        self?.models = models
        self?._changeModelsObservable.accept(())
      }) { (error) in
        guard let _error = error else { return }
        debugPrint(_error)
      }
    }).disposed(by: disposeBag)    
  }
}
