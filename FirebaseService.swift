//
//  FirebaseService.swift
//
//  Created by Jonathan Flintham on 12/05/2022.
//  Copyright © 2022 Future Workshops. All rights reserved.
//

import Foundation
import MobileWorkflowCore
import FirebaseCore
import FirebaseAnalytics

/// Service configuration needs to come from bundled `GoogleServices-Info.plist`
/// These settings should also be set in the app's `Info.plist`:
/// - Disable automatic screenview tracking by setting `FirebaseAutomaticScreenReportingEnabled` to `NO`
/// - Disable device tracking using Identifier for Vender (IDFV) by setting `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED` to `NO`
/// - Disable Personalised Advertising by setting `GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS` to `NO`
struct FirebaseService: AsyncTaskService {
    
    func canPerform<T>(task: T) -> Bool where T : AsyncTask {
        switch task {
        case is ARAnalyticsEventTask,
             is ARAnalyticsScreenViewTask:
            return true
        case is ARAnalyticsResetUserSessionTask:
            return false // not currently handled
        default:
            return false
        }
    }
    
    func perform<T>(task: T, session: ContentProvider, respondOn: DispatchQueue, completion: @escaping (Result<T.Response, Error>) -> Void) where T : AsyncTask {
        if let task = task as? ARAnalyticsEventTask {
            self.logEvent(task.input.name, parameters: task.input.parameters)
        } else if let task = task as? ARAnalyticsScreenViewTask {
            self.logScreenView(name: task.input.name, title: task.input.title)
        }
    }
    
    init() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
    }
    
    private func logEvent(_ name: String, parameters: [String: Any]?) {
        
        // Firebase only supports parameters of type NSString and NSNumber
        
        var converted = [String: AnyObject]()
        
        parameters?.forEach {
            if let stringValue = $0.value as? NSString {
                converted[$0.key] = stringValue
            } else if let numberValue = $0.value as? NSNumber {
                converted[$0.key] = numberValue
            }
        }
        
        FirebaseAnalytics.Analytics.logEvent(name, parameters: converted)
    }
    
    private func logScreenView(name: String, title: String) {
        
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: title as NSString,
            AnalyticsParameterScreenClass: name as NSString
        ])
    }
}
