//
//  Untitled.swift
//  SmartRecorder
//
//  Created by Виктория Мирошник on 23.10.2025.
//

import Foundation

final class Texts {
    enum AppInfo {
        static let title = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Transono"
    }
    
    enum NavigationBar {
        static let location = "Местоположение"
    }
}
