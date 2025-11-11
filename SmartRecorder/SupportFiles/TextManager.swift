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
    
    enum Tabbar {
        static let notes = "Записи"
        static let recorder = "Диктофон"
        static let profile = "Профиль"
        static let search = "Поиск"
    }
    
    enum NavigationBar {
        static let location = "Местоположение"
    }
    
    enum OnboardingPage {
        static let skip = "Пропустить"
        static let next = "Далее"
        static let permission = "Разрешить"
        static let skipPermission = "Позже"
        
        enum FirstPage {
            static let title = "Умный микрофон"
            static let description = "Ваш диктофон может гораздо больше, чем просто записывать."
        }
        enum SecondPage {
            static let title = "Сводка записи"
            static let description = "ИИ проведет расшифровку записей и создаст сводку."
        }
        enum ThirdPage {
            static let title = "Микрофон"
            static let description = "Разрешите доступ к микрофону, чтобы записывать встречи."
        }
        enum FourthPage {
            static let title = "Местоположение"
            static let description = "Позволит сохранять информацию о месте записи заметки."
        }
    }
    
    enum NotesPage {
        static let title = "Мои записи"
        static let search = "Поиск"
    }
    
    enum UserDefaults {
        static let skipOnboarding = "SkipOnboardingStage"
    }
    
    enum GlassEffectId {
        enum Onboarding {
            static let permission = "OnboardingPermissionGlassEffect"
            static let skipPermission = "OnboardingSkipPermissionGlassEffect"
        }
    }
}
