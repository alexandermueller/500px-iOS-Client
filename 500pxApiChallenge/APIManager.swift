//
//  APIManager.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import RxSwift
import Foundation

struct ImageJSONData: Codable {
    var currentPage: Int
    var totalPages: Int
    var totalItems: Int
    var photos: [Image]
}

class APIManager {
    var consumerKey: String? {
        do {
            if let path = Bundle.main.path(forResource: "API", ofType: "key") {
                return try String(contentsOfFile: path, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
            }
        } catch {}
        
        return nil
    }
    
    func fetchPageDataFor(feature: String, page: Int, size: Int) -> BehaviorSubject<[Image]> {
        let imagesSubject = BehaviorSubject<[Image]>(value: [])
        
        guard let key = consumerKey, let url = URL(string: "https://api.500px.com/v1/photos?feature=\(feature)&page=\(page)&image_size=\(size)&consumer_key=\(key)") else {
            return BehaviorSubject<[Image]>(value: [])
        }
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let error = error {
                print("FetchImages error: \(error)")
                return
            }
            
            guard let response = response else {
                print("FetchImages response error: response is nil")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("FetchImages response error: \(response))")
                return
            }
            
            guard let jsonData = data else {
                print("FetchImages json data error: data is nil")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedPageData = try JSONDecoder().decode(ImageJSONData.self, from: jsonData)
                
                //TODO: Decode page data and parse json here
                
                imagesSubject.onNext([])
            } catch {
                print("FetchImages json decoding error")
            }
        })
        
        task.resume()
        return imagesSubject
    }
}
