//
//  File.swift
//  SampleRxSwift
//
//  Created by sakiyamaK on 2020/05/23.
//  Copyright © 2020 sakiyamaK. All rights reserved.
//

import UIKit

final class GithubTableViewCell: UITableViewCell {
  
  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var urlLabel: UILabel!

  func configure(githubModel: GithubModel) {
    titleLabel.text = githubModel.name
    urlLabel.text = githubModel.urlStr
  }
}
