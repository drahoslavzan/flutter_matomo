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
    
    private func trackDownloadInternal(){
        guard matomoTracker != nil else {return}
        let urlString = "/application/downloaded?download=\(getInstallIdentifier())"

        let event = Event(tracker: matomoTracker!, action: ["application/downloaded"], url: URL(string: urlString), referer: nil, eventCategory: "Application", eventAction: "downloaded" )
        matomoTracker?.track(event)

    }

    private func getInstallIdentifier() -> String {
        return "http://\(String(describing: Bundle.main.bundleIdentifier)):\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
    }

    private func trackCartUpdate(itemsNumber: Int) {
        guard matomoTracker != nil else {return}

        var counter = itemsNumber

        var items = [OrderItem]()

        repeat {
            items.append(OrderItem(sku: ""))
            counter -= 1
        } while counter > 0

        let event = Event(tracker: matomoTracker!, action: [String](), orderItems: items)
        matomoTracker?.track(event)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method.elementsEqual("initializeTracker")){
            guard let arguments = call.arguments as? NSDictionary,
                let url = arguments["url"] as? String,
                let siteId = arguments["siteId"] as? Int else { return }
            matomoTracker = MatomoTracker(siteId: String(siteId), baseURL: URL(string: url)!)
            matomoTracker?.logger = DefaultLogger(minLevel: .verbose)
            if (!UserDefaults.standard.bool(forKey: "isInstalled")){
                trackDownloadInternal()
                UserDefaults.standard.set(true, forKey: "isInstalled")
            }

            result("Matomo:: \(url) initialized successfully.")
        }
        if(call.method.elementsEqual("trackEvent")){
            guard let arguments = call.arguments as? NSDictionary,
                let widgetName = arguments["widgetName"] as? String,
                let eventName =  arguments["eventName"] as? String,
                let eventAction =  arguments["eventAction"] as? String else { return }
            matomoTracker?.track(eventWithCategory: widgetName, action: eventAction, name: eventName, number: 3)
            matomoTracker?.dispatch()
            result("Matomo:: trackScreen event \(eventName) sent")
        }
        if(call.method.elementsEqual("trackEventWithOptionalName")){
            guard let arguments = call.arguments as? NSDictionary,
                let widgetName = arguments["widgetName"] as? String,
                let eventName =  arguments["eventName"] as? String,
                let eventAction =  arguments["eventAction"] as? String,
                let optionalName =  arguments["optionalName"] as? String else { return }
            matomoTracker?.track(eventWithCategory: widgetName, action: eventAction, name: optionalName, number: 3)
            matomoTracker?.dispatch()
            result("Matomo:: trackScreen event \(eventName) sent")
        }
        if(call.method.elementsEqual("trackScreen")){
            guard let arguments = call.arguments as? NSDictionary,
                let widgetName = arguments["widgetName"] as? String else { return }
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
           // matomoTracker?.dispatch()
            result("Matomo:: events dispatched")
        }
        if (call.method.elementsEqual("trackCartUpdate")) {
            guard let arguments = call.arguments as? NSDictionary,
                let totalCount = arguments["totalCount"] as? Int else { return }
            trackCartUpdate(itemsNumber: totalCount)
            result("Matomo:: cartUpdate sent")
        }
        if (call.method.elementsEqual("trackOrder")) {
            guard let arguments = call.arguments as? NSDictionary,
                let orderId = arguments["goalId"] as? String,
                let items = arguments["items"] as? [OrderItem] else { return }
            
            let revenue = arguments["totalPrice"] as! Int
            matomoTracker?.trackOrder(id: orderId, items: items, revenue: Float(revenue))
            matomoTracker?.dispatch()
            result("Matomo:: trackOrder sent")
        }

    }
}
