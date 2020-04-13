//
//  Store.swift
//  Magic
//
//  Created by Andrew Finke on 11/16/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import StoreKit
import os.log

class PlusStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    // MARK: - Types -
    
    enum MagicError: Error {
        case unableToMakePayments
        case noProduct
        case networkError(Error)
        case serverError
    }
    
    enum ProductType {
        case unlock
        
        var identifier: String {
            let bundle = "com.andrewfinke.space.golf."
            switch self {
            case .unlock:
                return bundle + "unlock"
            }
        }
    }
    
    // MARK: - Properties -
    
    static let shared = PlusStore()
    static let productsUpdatedNotificationName = Notification.Name("productsUpdatedNotificationName")
    
    private let queue = SKPaymentQueue.default()
    var products: (standard: MagicSubscription, ultimate: MagicSubscription)?
    private var purchaseHandler: ((_ result: Result<Bool, MagicError>) -> Void)?
    
    private var verifyReceiptTimer: Timer?
    private var paymentQueueTransactions: [SKPaymentTransaction] = []
    private let paymentQueueTransactionsQueue = DispatchQueue(label: "com.andrewfinke.Magic.store.queue",
                                                              qos: .userInitiated)
    
    var isPlus = false

    // MARK: - Initalization -
    
    private override init() {
        super.init()
        queue.add(self)
    }
    
    // MARK: - Helpers -
    
    func sync() {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        let request = SKProductsRequest(productIdentifiers: [
            PlusStore.PlusType.standard.identifier,
            PlusStore.PlusType.ultimate.identifier
        ])
        request.delegate = self
        request.start()
        startVerifyReceiptTimer()
    }
    
    func restore() {
        os_log("%{public}s: restore", log: .store, type: .info, #function)
        queue.restoreCompletedTransactions()
    }
    
    func purchase(type: PlusType, completion: @escaping (_ result: Result<Bool, MagicError>) -> Void) {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        
        guard SKPaymentQueue.canMakePayments() else {
            os_log("%{public}s: unableToMakePayments", log: .store, type: .error, #function)
            completion(.failure(.unableToMakePayments))
            return
        }
        
        guard let products = self.products else {
            os_log("%{public}s: noProduct", log: .store, type: .error, #function)
            completion(.failure(.noProduct))
            return
        }
        
        self.purchaseHandler = completion
        
        let product: SKProduct
        switch type {
        case .standard:
            product = products.standard.raw
        case .ultimate:
            product = products.ultimate.raw
        }
        let payment = SKPayment(product: product)
        queue.add(payment)
    }
    
    // MARK: - SKProductsRequestDelegate -
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        os_log("%{public}s: called", log: .store, type: .info, #function)

        var standard: SKProduct?
        var ultimate: SKProduct?
        for product in response.products {
            if product.productIdentifier == PlusType.standard.identifier {
                standard = product
            } else if product.productIdentifier == PlusType.ultimate.identifier {
                ultimate = product
            } else {
                fatalError()
            }
        }
        
        guard let s = MagicSubscription(standard), let u = MagicSubscription(ultimate) else {
            os_log("%{public}s: don't have both products", log: .store, type: .error, #function)
            return
        }
        products = (s, u)
        NotificationCenter.default.post(name: PlusStore.productsUpdatedNotificationName, object: nil)
        
        os_log("%{public}s: products: %{public}@, %{public}@", log: .store, type: .error, #function, s.price, u.price)
    }
    
    // MARK: - SKPaymentTransactionObserver -
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                os_log("%{public}s: purchasing", log: .store, type: .info, #function)
            case .purchased:
                os_log("%{public}s: purchased", log: .store, type: .info, #function)
                addToQueue(transaction: transaction)
            case .failed:
                os_log("%{public}s: failed", log: .store, type: .info, #function)
                addToQueue(transaction: transaction)
            case .restored:
                os_log("%{public}s: restored", log: .store, type: .info, #function)
                addToQueue(transaction: transaction)
            case .deferred:
                os_log("%{public}s: deferred", log: .store, type: .info, #function)
                break
            @unknown default:
                os_log("%{public}s: unknown", log: .store, type: .info, #function)
                break
            }
        }
    }
    
    // MARK: - Helpers -
    
    func addToQueue(transaction: SKPaymentTransaction) {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        paymentQueueTransactionsQueue.sync {
            self.paymentQueueTransactions.append(transaction)
        }
        startVerifyReceiptTimer()
    }
    
    func startVerifyReceiptTimer() {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        verifyReceiptTimer?.invalidate()
        verifyReceiptTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                 target: self,
                                                 selector: #selector(processPaymentQueueTransactions),
                                                 userInfo: nil,
                                                 repeats: false)
    }
    
    @objc
    func processPaymentQueueTransactions() {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        
        paymentQueueTransactionsQueue.async {
            let transactions = self.paymentQueueTransactions
            self.paymentQueueTransactions = []
            
            DispatchQueue.global().async {
                self.verifyReceipt { isValid in
                    self.purchaseHandler?(.success(isValid))
                    self.purchaseHandler = nil
                    for transaction in transactions {
                        self.queue.finishTransaction(transaction)
                    }
                }
            }
        }
    }
    
    func verifyReceipt(completion: ((_ isValid: Bool) -> Void)?) {
        os_log("%{public}s: called", log: .store, type: .info, #function)
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            completion?(false)
            os_log("%{public}s: no url", log: .store, type: .error, #function)
            return
        }
        
        guard let rawReceiptData = try? Data(contentsOf: appStoreReceiptURL) else {
            completion?(false)
            os_log("%{public}s: no data at url %{public}s", log: .store, type: .error, #function, appStoreReceiptURL.description)
            return
        }
        
        let receiptData = rawReceiptData.base64EncodedString()
        let jsonObject = ["receipt-data": receiptData]
        
        var components = URLComponents(string: resort.verifyRecieptURL.absoluteString)
        components?.queryItems = MagicRequest.queryItems(reason: .generic)
        guard let url = components?.url else { fatalError() }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonObject)
        
        struct Response: Codable {
            let isValidSubscription: Bool
        }
        
        os_log("%{public}s: sending request", log: .store, type: .info, #function)
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                os_log("%{public}s: response error: %{public}s", log: .store, type: .error, #function, error.localizedDescription)
                completion?(false)
            } else if let data = data, let object = try? JSONDecoder().decode(Response.self, from: data) {
                os_log("%{public}s: isValidSubscription: %{public}d", log: .store, type: .info, #function, object.isValidSubscription)
                self.isPlus = object.isValidSubscription
                completion?(self.isPlus)
            } else {
                os_log("%{public}s: unknown outcome", log: .store, type: .info, #function)
            }
        }
        task.resume()
    }
    
}
