//
//  rive_animatedApp.swift
//  rive-animated
//
//  Created by vijay verma on 17/02/25.
//

import SwiftUI

@main
struct rive_animatedApp: App {
    var body: some Scene {
        WindowGroup {
            LightBulbView().preferredColorScheme(.dark)
                .background(Color("LaunchScreenBackgroundColor"))
        }
    }
}
