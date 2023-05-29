import ApphudSDK
import StoreKit

@objc(ApphudSdk)
class ApphudSdk: NSObject {
    
    override init() {
        ApphudHttpClient.shared.sdkType = "reactnative";
        ApphudHttpClient.shared.sdkVersion = "1.1.0";
    }

    @objc(start:withResolver:withRejecter:)
    func start(options: NSDictionary, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let apiKey = options["apiKey"] as! String;
        let userID = options["userId"] as? String;
        let observerMode = options["observerMode"] as? Bool ?? true;
        Apphud.start(apiKey: apiKey, userID: userID, observerMode: observerMode);
        resolve(true);
    }
    
    @objc(startManually:withResolver:withRejecter:)
    func startManually(options: NSDictionary, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let apiKey = options["apiKey"] as! String;
        let userID = options["userId"] as? String;
        let deviceID = options["deviceId"] as? String;
        let observerMode = options["observerMode"] as? Bool ?? true;
        Apphud.startManually(apiKey: apiKey, userID: userID, deviceID: deviceID, observerMode: observerMode);
        resolve(true);
    }
    
    @objc(logout:withRejecter:)
    func logout(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        Apphud.logout();
        resolve(true);
    }
    
    @objc(hasActiveSubscription:withRejecter:)
    func hasActiveSubscription(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        resolve(Apphud.hasActiveSubscription());
    }
    
    @objc(products:withRejecter:)
    func products(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let products:[SKProduct]? = Apphud.products;
        resolve(
            products?.map{ (product) -> NSDictionary in
                return DataTransformer.skProduct(product: product);
            }
        );
    }
    
    @objc(product:withResolver:withRejecter:)
    func product(productIdentifier:String, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        resolve(
            Apphud.product(productIdentifier: productIdentifier)
        );
    }
    
    @objc(purchase:withResolver:withRejecter:)
    func purchase(productIdentifier:String,  resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        Apphud.purchase(productIdentifier) { (result:ApphudPurchaseResult) in

            var response = [
                "subscription": DataTransformer.apphudSubscription(subscription: result.subscription),
                "nonRenewingPurchase": DataTransformer.nonRenewingPurchase(nonRenewingPurchase: result.nonRenewingPurchase),
            ]

            if let err = result.error as? NSError {
                response["error"] = [
                    "errorCode": err.code,
                    "localizedDescription": err.localizedDescription,
                    "errorUserInfo": err.userInfo,
                ]
            }

            if let transaction = result.transaction {
                response["transaction"] = [
                    "transactionIdentifier": transaction.transactionIdentifier ?? "",
                    "transactionDate": transaction.transactionDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
                    "payment": [
                        "productIdentifier": transaction.payment.productIdentifier
                    ]
                ]
            }
            resolve(response);
        }
    }
    
    @objc(purchaseProduct:withResolver:withRejecter:)
    func purchaseProduct(args: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        let productId = args["productId"] as! String;
        let paywallId = args["paywallId"] as! String;
        var product:ApphudProduct?;
        let paywalls = Apphud.paywalls ?? [];
        for paywall in paywalls where product==nil {
            product = paywall.products.first { product in
                return product.productId == productId && product.paywallId == paywallId
            }
        }
        if (product != nil) {
            Apphud.purchase(product!) { result in

                var response = [
                    "subscription": DataTransformer.apphudSubscription(subscription: result.subscription),
                    "nonRenewingPurchase": DataTransformer.nonRenewingPurchase(nonRenewingPurchase: result.nonRenewingPurchase),

                ]

                if let err = result.error as? NSError {
                    response["error"] = [
                        "errorCode": err.code,
                        "localizedDescription": err.localizedDescription,
                        "errorUserInfo": err.userInfo,
                    ]
                }


                if let transaction = result.transaction {
                    response["transaction"] = [
                        "transactionIdentifier": transaction.transactionIdentifier ?? "",
                        "transactionDate": transaction.transactionDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
                        "payment": [
                            "productIdentifier": transaction.payment.productIdentifier
                        ]
                    ]
                }

                resolve(response);
            }
        } else {
            reject("Error", "Product not found", nil);
        }
    }
    
    @objc(willPurchaseFromPaywall:withResolver:withRejecter:)
    func willPurchaseFromPaywall(productIdentifier:String,  resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        Apphud.willPurchaseProductFromPaywall(productIdentifier);
    }
    
    @objc(paywallsDidLoadCallback:withRejecter:)
    func paywallsDidLoadCallback(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        Apphud.paywallsDidLoadCallback { paywalls in
            resolve(
                paywalls.map({ paywall in
                    return paywall.toMap();
                })
            );
        }
    }
    
    @objc(submitPushNotificationsToken:withResolver:withRejecter:)
    func submitPushNotificationsToken(token:String,  resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let data: Data = (token).data(using: .utf8)!;
        Apphud.submitPushNotificationsToken(token: data) { result in
            resolve(result);
        }
    }
    
    @objc(apsInfo:withResolver:withRejecter:)
    func handlePushNotification(apsInfo: NSDictionary,  resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        var payload = [AnyHashable:Any]();
        apsInfo.allKeys.forEach { key in
            let prop: AnyHashable = key as! AnyHashable;
            payload[prop] = apsInfo[key];
        }
        resolve(
            Apphud.handlePushNotification(apsInfo: payload)
        )
    }
    
    @objc(subscription:withRejecter:)
    func subscription(resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let subscription = Apphud.subscription();
        resolve(DataTransformer.apphudSubscription(subscription: subscription));
    }
    
    @objc(isNonRenewingPurchaseActive:withResolver:withRejecter:)
    func isNonRenewingPurchaseActive(productIdentifier: String, resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        resolve(
            Apphud.isNonRenewingPurchaseActive(productIdentifier: productIdentifier)
        );
    }
    
    @objc(nonRenewingPurchases:withRejecter:)
    func nonRenewingPurchases(resolve: RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let purchases = Apphud.nonRenewingPurchases();
        resolve(
            purchases?.map({ (purchase) -> NSDictionary in
                return DataTransformer.nonRenewingPurchase(nonRenewingPurchase: purchase);
            })
        );
    }
    
    @objc(restorePurchases:withRejecter:)
    func restorePurchases(resolve: @escaping RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        Apphud.restorePurchases { (subscriptions, purchases, error) in
            resolve([
                "subscriptions": subscriptions?.map{ (subscription) -> NSDictionary in
                    return DataTransformer.apphudSubscription(subscription: subscription);
                } as Any,
                "purchases": purchases?.map{ (purchase) -> NSDictionary in
                    return [
                        "productId": purchase.productId,
                        "canceledAt": purchase.canceledAt?.timeIntervalSince1970 as Any,
                        "purchasedAt": purchase.purchasedAt.timeIntervalSince1970 as Any
                    ]
                } as Any,
                "error": error?.localizedDescription as Any,
            ])
        }
    }
    
    @objc(userId:withRejecter:)
    func userId(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        resolve(
            Apphud.userID()
        );
    }
    
    @objc(addAttribution:withResolver:withRejecter:)
    func addAttribution(options: NSDictionary, resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        let data = options["data"] as! [AnyHashable : Any];
        let identifier = options["identifier"] as? String;
        let from:ApphudAttributionProvider? = ApphudAttributionProvider(rawValue: options["attributionProviderId"] as! Int);
        Apphud.addAttribution(data: data, from: from!, identifer: identifier) {  (result:Bool) in
            resolve(result);
        }
    }
    
    @objc(appStoreReceipt:withRejecter:)
    func appStoreReceipt(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        resolve(
            Apphud.appStoreReceipt()
        );
    }
    
    @objc(setUserProperty:withValue:withSetOnce:withResolver:withRejecter:)
    func setUserProperty(key: String, value: String, setOnce: Bool, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let _key = ApphudUserPropertyKey.init(key)
        resolve(Apphud.setUserProperty(key: _key, value: value, setOnce: setOnce));
    }
    
    @objc(incrementUserProperty:withBy:withResolver:withRejecter:)
    func incrementUserProperty(key: String, by: String, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        let _key = ApphudUserPropertyKey.init(key)
        resolve(Apphud.incrementUserProperty(key: _key, by: by));
    }
    
    @objc(subscriptions:withRejecter:)
    func subscriptions(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        reject("Error method", "Unsupported method", nil);
    }
    
    @objc(syncPurchases:withRejecter:)
    func syncPurchases(resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
        reject("Error method", "Unsupported method", nil);
    }
}
