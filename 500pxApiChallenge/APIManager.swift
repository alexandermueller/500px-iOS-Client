//
//  APIManager.swift
//  500pxApiChallenge
//
//  Created by Alex Mueller on 2020-07-17.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import RxSwift
import Foundation

// 500px API's cache lifetime (5 min)
let kAPICacheLifeTimeInterval = TimeInterval(5 * 60)

/* APIManager:
 * - Abstracts away and handles all direct interaction with the 500px API
 *
 * consumerKey: grabs the consumer key value stored inside the Assets/API.key raw text file.
 */
class APIManager {
    var consumerKey: String? {
        do {
            if let path = Bundle.main.path(forResource: "API", ofType: "key") {
                return try String(contentsOfFile: path, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
            }
        } catch {
            print("Fetchimages consumer key error: \(error)")
        }
        
        return nil
    }
    
    /* fetchPageDataFor:feature:page:invalidPageDataSubject:
     * - Performs a data request to the 500px API using the given feature page, page number, and consumer key.
     *   If the request is successful, the function will attempt to decode the JSON data into a PageData struct. The PageData
     *   struct is a nested struct of JSON coders that emulate a simplified view of the JSON returned.
     *
     * - invalidPageDataSubject is either an already existing invalid PageData subject, or nil if the page doesn't exist yet
     *   in the PageData cache. See ValidatedPageDataSubjectCache for more information about the cache itself.
     *
     * - Returns a PageData BehaviorSubject. If the page has been visited before but the PageData is invalid, then it will
     *   return and put any parsed PageData into the invalidPageDataSubject, otherwise the page hasn't been visited before, so
     *   it returns a fresh PageData BehaviorSubject and puts any parsed PageData into the new subject.
     *
     * - In the interest of time, I decided to leave this where it is now, but if I had more time to flesh it out, I would love
     *   this to onError (or something similar) when something goes wrong to signal downstream listeners that there was an issue.
     *   This way, the user can be notified and attempt another fetch in case the server is unavailable (by dragging down on the
     *   UIScrollView, etc.)
     */
    @discardableResult func fetchPageDataFor(feature: String, page: Int, invalidPageDataSubject: BehaviorSubject<PageData>?) -> BehaviorSubject<PageData> {
        let pageDataSubject = invalidPageDataSubject ?? BehaviorSubject<PageData>(value: .defaultPageData())
        
        guard let key = consumerKey, let url = URL(string: "https://api.500px.com/v1/photos?feature=\(feature)&page=\(page)&consumer_key=\(key)") else {
            if consumerKey != nil {
                print("FetchImages error: \(consumerKey == nil ? "key should not be nil" : "api url should not be nil")")
            }
            
            return pageDataSubject
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
                decoder.keyDecodingStrategy = .convertFromSnakeCase // converts from abc_var_name to abcVarName
                
                let decodedPageData: PageData = try decoder.decode(PageData.self, from: jsonData)
                pageDataSubject.onNext(decodedPageData)
            } catch {
                print("FetchImages json decoding error: \(error)")
            }
        })
        
        task.resume()
        return pageDataSubject
    }
}
