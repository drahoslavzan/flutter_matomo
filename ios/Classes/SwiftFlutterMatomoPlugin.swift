import Flutter
import UIKit
import MatomoTracker


public class SwiftFlutterMatomoPlugin: NSObject, FlutterPlugin {
    
    var matomoTracker: MatomoTracker? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_matomo", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterMatomoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private func trackCartUpdate(itemsNumber: Int) {
        let event = Event(tracker: self, action: [], itemsNumber: itemsNumber)
        matomoTracker?.track(event)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method.elementsEqual("initializeTracker")){
            guard let arguments = call.arguments as? NSDictionary,
                let url = arguments?["url"] as? String,
                let siteId = arguments?["siteId"] as? Int else { return }
            matomoTracker = MatomoTracker(siteId: String(siteId), baseURL: URL(string: url)!)
            matomoTracker?.logger = DefaultLogger(minLevel: .verbose)
            result("Matomo:: \(url) initialized successfully.")
        }
        if(call.method.elementsEqual("trackEvent")){
            guard let arguments = call.arguments as? NSDictionary,
                let widgetName = arguments?["widgetName"] as? String,
                let eventName =  arguments?["eventName"] as? String,
                let eventAction =  arguments?["eventAction"] as? String else { return }
            matomoTracker?.track(eventWithCategory: widgetName, action: eventAction, name: eventName, number: 3)
            matomoTracker?.dispatch()
            result("Matomo:: trackScreen event \(eventName) sent")
        }
        if(call.method.elementsEqual("trackScreen")){
            guard let arguments = call.arguments as? NSDictionary,
                let widgetName = arguments?["widgetName"] as? String else { return }
            matomoTracker?.track(view:[widgetName])
            matomoTracker?.dispatch()
            result("Matomo:: trackScreen screen \(widgetName) sent")
        }
        if(call.method.elementsEqual("trackDownload")){
            result("Matomo:: trackDownload initialized successfully.")
        }
        if(call.method.elementsEqual("trackGoals")){
            result("Matomo:: trackGoals initialized successfully.")
        }
        if(call.method.elementsEqual("dispatchEvents")){
            matomoTracker?.dispatch()
            result("Matomo:: events dispatched")
        }
        if (call.method.elementsEqual("cartUpdate")) {
            guard let arguments = call.arguments as? NSDictionary,
                let totalCount = (arguments["items"] as? [OrderItem]).count
            matomoTracker?.trackCartUpdate(items: totalCount)
        }
        if (call.method.elementsEqual("trackOrder")) {
            guard let arguments = call.arguments as? NSDictionary,
                let orderId = arguments["id"] as? String,
                let items = arguments["items"] as? [OrderItem] else { return }
            let revenue = {
                var totalPrice: Float = 0.0
                for item in items {
                    totalPrice += item.price * item.quntity
                }
                return totalPrice
            }
            matomoTracker?.trackOrder(id: orderId, items: items, revenue: revenue)
        }
    }
}
