//
//  GithubAPI.swift
//  SampleRxSwift
//
//  Created by sakiyamaK on 2020/05/23.
//  Copyright © 2020 sakiyamaK. All rights reserved.
//

import Foundation
import Alamofire

final class GithubAPI {
  static let shared = GithubAPI()

  private init() {}

  func get(searchWord: String, isDesc: Bool = true, success: (([GithubModel]) -> Void)? = nil, error: ((String?)->Void)? = nil) {
    AF.request("https://api.github.com/search/repositories?q=\(searchWord)&sort=stars&order=\(isDesc ? "desc" : "asc")").response { (response) in
//      debugPrint(response.request)
      switch response.result {
      case .success:
        guard
          let data = response.data,
          let githubResponse = try? JSONDecoder().decode(GithubResponse.self, from: data),
          let models = githubResponse.items
        else
        {
          success?([])
          return
        }
        success?(models)
      case .failure(let err):
        debugPrint(err)
        error?(err.errorDescription)
      }
    }
  }
}
