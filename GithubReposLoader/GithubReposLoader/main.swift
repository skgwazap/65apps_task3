//
//  main.swift
//  GithubReposLoader
//
//  Created by Taras Kreknin on 30.07.2020.
//  Copyright © 2020 SKGWAZAP. All rights reserved.
//

import Foundation
import ArgumentParser

private let fetcher: ReposFetching = GithubReposFetcher()
private var fetchedRepositories: [Repository] = []

struct FetchRepoNames: ParsableCommand {
    
    private let nicknameErrorDesc = """
Username may only contain alphanumeric characters or single hyphens, and cannot begin or end with a hyphen. Maximum 39 characters.
"""
    
    static let configuration = CommandConfiguration(abstract: "Fetches list of user's Github repositories")
    
    @Argument(help: "Username of a GitHub user")
    var nickname: String
    
    func validate() throws {
        let pattern = #"^[a-zA-z\d](?:[a-zA-z\d]|-(?=[a-zA-Z\d])){0,38}$"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(nickname.startIndex..<nickname.endIndex, in: nickname)
        let match = regex.firstMatch(in: nickname, options: [], range: range)
        if match == nil {
            throw ValidationError("Invalid username provided <\(nickname)>.\n\(nicknameErrorDesc)")
        }
    }
    
    func run() throws {
        print("Fetching repositories of <\(nickname)>")
        fetch(nickname: nickname, page: 1, perPage: 100) { repos in
            repos.forEach { repo in
                print(repo.name)
            }
            Self.exit(withError: nil)
        }
    }
    
    private func fetch(nickname: String, page: Int, perPage: Int, onComplete: @escaping ([Repository]) -> Void) {
        fetcher.fetchRepositoriesOfUser(nickname: nickname, page: page, perPage: perPage) { fetchResult in
            switch fetchResult {
            case .success(let repos):
                fetchedRepositories += repos
                let hasMoreToFetch = repos.count == perPage
                if hasMoreToFetch {
                    self.fetch(nickname: nickname, page: page + 1, perPage: perPage, onComplete: onComplete)
                } else {
                    onComplete(fetchedRepositories)
                }
            case .failure(let error):
                // TODO better error handling
                print("Got an error \(error)")
                Self.exit(withError: error)
            }
        }
    }
    
}

FetchRepoNames.main()

dispatchMain()
