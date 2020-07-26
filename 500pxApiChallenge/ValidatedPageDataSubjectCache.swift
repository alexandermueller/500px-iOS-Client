//
//  ValidatedPageDataSubjectCache.swift
//  500pxApiChallenge
//
//  Created by Alexander Mueller on 2020-07-19.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

/* ValidatedPageDataSubject
 * - A self-invalidating PageData subject wrapper class.
 *
 *           index: The corresponding page index of the PageData
 *         isValid: A flag that determines if the data stored is still fresh and doesn't require refreshing
 * pageDataSubject: The PageData subject returned by requests made through the APIManager
 * validationTimer: A timer that invalidates the object as soon as the timer runs out
 */
fileprivate class ValidatedPageDataSubject {
    private var index: Int
    private var isValid = false
    private var pageDataSubject: BehaviorSubject<PageData>
    private var validationTimer: Timer = Timer()
    
    init(_ pageDataSubject: BehaviorSubject<PageData>, index: Int) {
        self.index = index
        self.pageDataSubject = pageDataSubject
        validate()
    }
    
    func getPageDataSubject() -> BehaviorSubject<PageData> {
        return pageDataSubject
    }
    
    /* validate:
     * - Sets the isValid flag to true, and triggers a timer with the same duration as the API cache lifetime.
     *   Once the timer is up, it invalidates the object by setting isValid to false.
     */
    func validate() {
        isValid = true
        validationTimer = Timer.scheduledTimer(withTimeInterval: kAPICacheLifeTimeInterval, repeats: false, block: { [weak self] timer in
            DispatchQueue.main.async {
                self?.isValid = false
            }
        })
    }
    
    /* value:
     * - Returns a the PageData subject if the object is still valid, otherwise returns nil.
     */
    func value() -> BehaviorSubject<PageData>? {
        return isValid ? pageDataSubject : nil
    }
}

/* ValidatedPageDataSubjectCache:
 * - Abstracts a cache of PageData subjects via a dictionary of page index keys mapped to
 *   self-invalidating PageData subject values.
 *
 * cache: The dictionary that contains the self-invalidating PageData subjects.
 */
class ValidatedPageDataSubjectCache {
    private var cache: [Int : ValidatedPageDataSubject] = [:]

    /* fetch:at:index:
     * - Returns either a valid PageData subject at the given index, or nil if the PageData subject is
     *   invalid or doesn't exist yet in the cache.
     */
    func fetch(at index: Int) -> BehaviorSubject<PageData>? {
        return cache[index]?.value()
    }
    
    /* fetchEvenIfInvalid:at:index:
     * - Similar to fetch:at:index:, except returns an existing PageData subject for a given index even
     *   if it's invalid.
     */
    func fetchEvenIfInvalid(at index: Int) -> BehaviorSubject<PageData>? {
        return cache[index]?.getPageDataSubject()
    }
    
    /* validateExistingOrSetNew:pageDataSubject:for:index:
     * - If the cache already contains a PageData subject at the given index, it will re-validate it,
     *   otherwise it will place the new PageData subject in the cache at the given index.
     */
    func validateExistingOrSetNew(_ pageDataSubject: BehaviorSubject<PageData>, for index: Int) {
        if let validatedPageDataSubject = cache[index] {
            validatedPageDataSubject.validate()
            return
        }
        
        cache[index] = ValidatedPageDataSubject(pageDataSubject, index: index)
    }
}
