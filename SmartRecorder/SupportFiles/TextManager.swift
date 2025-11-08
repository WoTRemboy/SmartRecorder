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
    
    enum OnboardingPage {
        static let skip = "Пропустить"
        static let next = "Далее"
        static let permission = "Разрешить"
        
        static let firstTitle = "Умный микрофон"
        static let firstDescription = "Ваш диктофон может гораздо больше, чем просто записывать."
        static let secondTitle = "Сводка записи"
        static let secondDescription = "ИИ проведет расшифровку записей и создаст сводку."
        static let thirdTitle = "Микрофон"
        static let thirdDescription = "Разрешите доступ к микрофону, чтобы записывать встречи."
        static let fourthTitle = "Местоположение"
        static let fourthDescription = "Позволит сохранять информацию о месте записи заметки."
    }
    
    enum UserDefaults {
        static let skipOnboarding = "SkipOnboardingView"
    }
}
