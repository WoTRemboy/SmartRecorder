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
        
        enum MicrophoneAlert {
            static let title = "Доступ к микрофону запрещен"
            static let content = "Чтобы продолжить, разрешите доступ в настройках."
            static let settings = "Настройки"
            static let cancel = "Отмена"
        }
    }
    
    enum NotesPage {
        static let title = "Мои записи"
        static let search = "Поиск"
        static let inProgress = "Заметка в обработке..."
        static let empty = "Нет записей"
        
        static let city = "Город"
        static let street = "Улица"
        
        static let pdf = "Поделиться PDF"
        static let audio = "Поделиться аудио"
        
        static let error = "Ошибка"
        static let ok = "Хорошо"
        
        static let loadSuccessFirst = "Загрузка"
        static let loadSuccessSecond = "завершена"
        static let loadError = "Ошибка загрузки"

        enum Enhancement {
            static let action = "Улучшить перевод"
            static let subtitle = "Прогонит запись через более точную модель и обновит текст"
            static let processing = "Улучшение..."
            static let successShort = "Успешно"
            static let processingDescription = "Тяжелая модель собирает более чистую и точную расшифровку"
            static let success = "Перевод улучшен"
            static let successDescription = "Новая версия текста уже сохранена в записи"

            enum ErrorAlert {
                static let title = "Не удалось улучшить перевод"
                static let ok = "Хорошо"
            }

            enum Errors {
                static let audioMissing = "Аудиофайл записи не найден."
                static let modelMissing = "Тяжелая модель не найдена в приложении."
                static let audioReadFailed = "Не удалось прочитать аудиофайл для повторной расшифровки."
                static let modelLoadFailed = "Не удалось загрузить тяжелую модель для повторной расшифровки."
                static let transcriptionFailed = "Ошибка повторной расшифровки."
                static let emptyTranscription = "Модель не вернула текст для этой записи."
            }
        }
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
        static let liveTranscriptTitle = "Живая расшифровка"
        static let liveTranscriptPlaceholder = "Речь появится здесь через несколько секунд после начала записи"
        static let liveTranscriptProcessing = "Распознаем текущий фрагмент..."
        
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
        
        enum Toasts {
            static let uploadSuccess = "Загружено на сервер"
            static let uploadFailed = "Ошибка загрузки на сервер"
            static let accessDenied = "Микрофон недоступен"
        }
    }
    
    enum ProfilePage {
        enum Registration {
            static let title = "Регистрация"
            static let action = "Зарегистрироваться"
            static let secondAction = "У меня есть аккаунт"
        }
        
        enum Login {
            static let title = "Вход"
            static let action = "Войти"
            static let secondAction = "Создать аккаунт"
        }
        
        enum FloatingFields {
            enum Nickname {
                static let title = "Имя пользователя"
                static let placeholder = "Nickname"
            }
            enum Email {
                static let title = "Электронная почта"
                static let placeholder = "email@example.com"
            }
            enum Password {
                static let title = "Пароль"
                static let placeholder = "••••••••"
            }
            enum PasswordConfirmation {
                static let title = "Подтверждение пароля"
                static let placeholder = "••••••••"
            }
        }
        
        enum Dashboard {
            static let title = "Мой профиль"
            static let email = "Email"
            
            enum Stats {
                static let meetings = "Проведено встреч"
                static let minutes = "Проведено минут во встречах"
            }
            
            enum Cache {
                static let title = "Очистить кэш"
                static let desctiption = "Сейчас записи занимают"
                static let memory = "памяти"
                static let confirm = "Вы уверены, что хотите очистить кэш?"
                static let action = "Очистить"
                static let cancel = "Отмена"
                static let success = "Кэш успешно очищен"
            }
            
            enum Logout {
                static let title = "Выйти"
                static let confirm = "Вы уверены, что хотите выйти?"
                static let action = "Выйти"
                static let cancel = "Отмена"
                static let success = "Выход выполнен"
            }
        }
        
        enum User {
            static let title = "Мой профиль"
        }
        
        enum Toasts {
            static let registrationSuccess = "Готово! Аккаунт создан"
            static let loginSuccess = "Вход выполнен"
        }
        
        enum ErrorAlert {
            static let title = "Ошибка"
            static let ok = "Хорошо"
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
            static let liveTranscript = "RecorderLiveTranscriptGlassEffect"
        }
    }
    
    enum GeometryEffectId {
        enum Recorder {
            static let control = "RecorderGeometryEffect"
            static let liveTranscript = "RecorderLiveTranscriptGeometryEffect"
        }
    }
    
    enum Button {
        static let recorder = "начать\nзапись"
    }
}
