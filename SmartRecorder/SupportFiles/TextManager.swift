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
    
    enum OnboardingPage {
        static let skip = "Пропустить"
        static let next = "Далее"
        static let begin = "Начать"
        static let forbidden = "Недоступно"
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
        
        enum LocationAlert {
            static let title = "Доступ к местоположению запрещен"
            static let content = "Чтобы продолжить, разрешите доступ в настройках."
            static let settings = "Настройки"
            static let cancel = "Отмена"
        }
    }
    
    enum NotesPage {
        static let title = "Мои записи"
        static let search = "Поиск"
    }
    
    enum NoteFolder {
        static let title = "Категории"
        static let all = "Все"
        static let work = "Работа"
        static let study = "Учёба"
        static let personal = "Личное"
    }
    
    enum RecorderPage {
        static let location = "Местоположение"
        static let message = "Ознакомиться с протоколом встречи после её окончания можно в архиве записей"
        static let range = "архиве записей"
        
        enum SaveSheet {
            static let title = "Название записи"
            static let folder = "Добавить в папку"
            
            static let ok = "Хорошо"
            static let save = "Сохранить"
            
            static let success = "Успешно"
            static let successMessage = "Запись была сохранена"

            static let failure = "Ошибка"
            static let failureMessage = "Что-то пошло не так"
        }
    }
    
    enum UserDefaults {
        static let skipOnboarding = "SkipOnboardingStage"
    }
    
    enum GlassEffectId {
        enum Onboarding {
            static let permission = "OnboardingPermissionGlassEffect"
            static let skipPermission = "OnboardingSkipPermissionGlassEffect"
        }
        
        enum Recorder {
            static let timer = "RecorderTimerGlassEffect"
            static let stop = "RecorderStopGlassEffect"
        }
    }
    
    enum GeometryEffectId {
        enum Recorder {
            static let control = "RecorderGeometryEffect"
        }
    }
    
    enum Button {
        static let recorder = "начать запись"
    }
}

