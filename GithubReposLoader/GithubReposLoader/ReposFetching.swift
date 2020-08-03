//
//  ReposFetching.swift
//  GithubReposLoader
//
//  Created by Taras Kreknin on 30.07.2020.
//  Copyright © 2020 SKGWAZAP. All rights reserved.
//

import Foundation
import Alamofire

protocol ReposFetching {
    func fetchRepositoriesOfUser(nickname: String,
                                 page: Int,
                                 perPage: Int,
                                 onComplete: @escaping (Result<[Repository], Error>) -> Void)
}

final class GithubReposFetcher: ReposFetching {
    
    private let headers: HTTPHeaders = ["Accept": "application/vnd.github.v3+json"]
    
    func fetchRepositoriesOfUser(nickname: String,
                                 page: Int,
                                 perPage: Int,
                                 onComplete: @escaping (Result<[Repository], Error>) -> Void) {
        
        AF.request(Endpoint.userRepositories(nickname: nickname),
                   method: .get,
                   parameters: PagingParameters(page: page, per_page: perPage),
                   headers: headers)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseDecodable(of: [Repository].self) { dataResponse in
                switch dataResponse.result {
                case .success(let repos):
                    onComplete(.success(repos))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
    }
    
}

private enum Endpoint: URLConvertible {
    case userRepositories(nickname: String)
    
    func asURL() throws -> URL {
        switch self {
        case .userRepositories(let nickname):
            return URL(string: "https://api.github.com/users/\(nickname)/repos")!
        }
    }
}

private struct PagingParameters: Encodable {
    let page: Int
    let per_page: Int
}
