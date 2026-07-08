<div align="center">
  <img src="https://github.com/user-attachments/assets/83685872-adc6-47e4-add1-30badc091c65" alt="Transono Logo" width="200" height="200">
  <h1>Transono: Smart Recorder</h1>
</div>

**Transono** - это современное приложение для записи аудио с последующей расшифровкой в текстовые заметки и их удобного экспорта.
Построено на SwiftUI с Liquid Glass UI, использует современную архитектуру и методы работы с файлами, а также поддерживает выгрузку PDF и аудио.
Смотреть [Демо](https://drive.google.com/drive/folders/1Au7ws64LHzV5or4Yi298XzVc4BQrKZDd?usp=sharing).

## Содержание 📋

- [Модули](#modules)
- [Дополнительные возможности](#features)
- [Технологии](#technologies)
- [Архитектура](#architecture)
- [Сборка и запуск](#build)
- [Требования](#requirements)

<h2 id="modules">Модули 🧩</h2>

### Вступление (Onboarding)
- Анимированный splash-экран с логотипом Transono
- Приветственный экран с кратким описанием возможностей
- Запрос доступа к микрофону и местоположению

<img src="https://github.com/user-attachments/assets/a02263ce-08f7-434a-b425-0d97b12b64bb" alt="Onboarding Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/5dfe051e-7ed4-4fd2-84e9-2e8a7f8ff0ef" alt="Onboarding Info" width="200" height="435">
<img src="https://github.com/user-attachments/assets/93053554-605b-4194-9cb5-845c0e89f4ea" alt="Onboarding Micro Request" width="200" height="435">

### Диктофон
- Запись аудио с помощью AVAudio Framework
- Блок с сегодняшней датой и текущим местоположением
- Эквалайзер на основе 16 амплитуд с обновлением 20 раз/сек

<img src="https://github.com/user-attachments/assets/b3d957f7-8961-4118-b507-6e106c989a0b" alt="Recorder Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/f40dbea7-afcd-4505-a94b-630c2bb4af97" alt="Start Record Page" width="200" height="435">
<img src="https://github.com/user-attachments/assets/a5a891c4-f650-488e-99d4-95d8e7a36083" alt="Record in Progress Page" width="200" height="435">

### Список заметок
- Лист заметок с поиском и сортировкой по папкам
- Каждая ячейка отображает заголовок, дату, состояние аудиофайла
- Если аудиофайл выгружен, то имеется возможность загрузить с сервера

<img src="https://github.com/user-attachments/assets/a02acc87-3ec8-4719-8261-ba4231638408" alt="Notes List Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/c6f33477-3fc5-4dd9-a47d-f3e501fd9ae0" alt="Notes List" width="200" height="435">
<img src="https://github.com/user-attachments/assets/9f02515c-ebd5-4a04-adfd-81df27fc9494" alt="Notes Search" width="200" height="435">

### Детали заметки
- Блок метаданных: название, дата создания, папка
- Блок местоположения: название города и улицы
- Блок аудиофайла: отображение длительности с возможностью вызова плеера

<img src="https://github.com/user-attachments/assets/495352e5-488c-4fb6-ab85-2afa821f886c" alt="Note Details Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/9fc726c7-8180-4fcd-91aa-d2ee2e62de91" alt="Details First" width="200" height="435">
<img src="https://github.com/user-attachments/assets/278fe16f-eb4c-4150-b29f-5e7bf5133f85" alt="Details Second" width="200" height="435">

### Плеер
- Блок метаданных: название, дата создания, местоположение
- Эквалайзер: аналогичен диктофону
- Блок управления: интерактивная полоса прогресса, кнопки Play/Pause и перемотки на +- 5 сек

<img src="https://github.com/user-attachments/assets/da4d8356-59e4-43d5-b522-1839a0722b82" alt="Player Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/b1391709-8f00-4a27-9d10-2732aee2b47f" alt="Player Paused" width="200" height="435">
<img src="https://github.com/user-attachments/assets/a9abd374-0233-4a5b-ab7a-e6700b0e3f5e" alt="Player Playing" width="200" height="435">

### Профиль (Sign In/Up)

- Два экрана с формами Вход и Регистрация
- Минимальные требования почты (@) и от 6 символов пароля
- Обработка состояний: успешно, неверный пароль, ошибка подключения и тд.

<img src="https://github.com/user-attachments/assets/b16b2705-061e-474a-a44a-396f28234dbb" alt="Sign In/Up Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/6b78fe16-f480-42c2-b1e4-3d546aa9940e" alt="Sign In" width="200" height="435">
<img src="https://github.com/user-attachments/assets/058a4ad6-7ddf-464c-ae89-b6a30a49da32" alt="Sign Up" width="200" height="435">

### Профиль (Dashboard)
- Блок с отображением email пользователя и его аватара с первой буквой названия почты
- Блок с статистикой профиля: общее количество записей и общее число записанных минут
- Блок кэша: отображение объёма аудиофайлов с возможностью их удаления

<img src="https://github.com/user-attachments/assets/7a0f644c-79e4-4e83-96fd-1c4298eb1054" alt="Profile Dashboard Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/5c552a98-ca01-407a-af27-8d723a2434c7" alt="New Profile" width="200" height="435">
<img src="https://github.com/user-attachments/assets/8fa77143-2f16-43ee-9d92-219bcdad9aaf" alt="Existed Profile" width="200" height="435">

<h2 id="features">Дополнительные возможности ⚒️</h2>

### Загрузка и выгрузка аудиофайлов
- Если аудиофайл заметки не хранится, то имеется возможность его загрузить
- Статус загрузки отображает стек Toast-уведомлений в нижней части экрана
- На странице профиля возможно очистить кэш, что приведет к удалению всех аудиофайлов

<img src="https://github.com/user-attachments/assets/8a149503-f723-42eb-a779-95ea0e1bc930" alt="Cache Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/14aaba83-eb4b-4cfb-8344-c94924d2293c" alt="Downloaded File" width="200" height="435">
<img src="https://github.com/user-attachments/assets/6ecadf42-8b93-4c7e-8624-c7922281bd2f" alt="Clear Cache" width="200" height="435">

### Экспорт PDF-отчёта или .m4a-аудиофайла 
- Меню для экспорта расположено на ячейке записи в списке и на странице деталей
- PDF-документ включает в себя название, время записи и расшифровку по тайм-кодам
- Аудиофайлом возможно поделиться в соцсетях, но и также сохранить на устройстве

<img src="https://github.com/user-attachments/assets/c2b09fff-1244-4399-afb1-d13e90708fb7" alt="Export Demo" width="200" height="435">
<img src="https://github.com/user-attachments/assets/a811fab3-5751-4c81-b305-3501dc284239" alt="PDF Document" width="200" height="435">
<img src="https://github.com/user-attachments/assets/15293c4e-10f2-4ebe-bf30-4a4494e27dcf" alt=".m4a File" width="200" height="435">

### Тёмная тема
- Цветовая схема для тёмной темы
- Автоматически выбирается в зависимости от системы

<img src="https://github.com/user-attachments/assets/87e51ec1-5d37-430a-b753-4c63172a542f" alt="Dark Main Page" width="200" height="435">
<img src="https://github.com/user-attachments/assets/0d0f0ec7-a147-43f5-b245-57b6090b8ab8" alt="Dark Profile Page" width="200" height="435">
<img src="https://github.com/user-attachments/assets/a42883a3-ac1e-4738-b4c0-686ce7f9cedd" alt="Dark Notes Page" width="200" height="435">

<h2 id="technologies">Технологии 💻</h2>

### iOS Frameworks
- **SwiftUI:** - работа современных адаптивных компонентов UI
- **AVFoundation** - запись и воспроизведение аудио
- **Core Data:** - хранение и управление данными
- **Combine:** - реактивный поток данных и управление состоянием
- **OSLog** - структурированное логирование
- **URLSession/Alamofire** — сетевые операции (в т.ч. загрузка PDF/аудио)

### Пользовательский интерфейс
- **Liquid Glass** - современный дизайн-код от Apple
- **Symbol Effect** - смена состояния SF Symbols (.drawOn и .replace)
- **Navigation Transition** - контекстные появления FullscreenCover (.zoom)
- **Matched Geometry Effect** - контекстные переходы одного view в другое (Start/Stop запись)
- **Pager** - сторонний фреймворк для реализации интерактивного Onboarding

### Иконка приложения
- **Icon Composer** - современный билдер иконок в стиле Liquid Glass от Apple
- Адаптация под состояния Any, Dark, Tinted

<img src="https://github.com/user-attachments/assets/f9729b30-899a-40fd-8d43-06a4a14eeee3" alt="Icon Composer" width="435" height="260">

<h2 id="architecture">Архитектура 🏗️</h2>

Приложение **Transono** имеет паттерн: MVVM + Router + Service Layer.

### Model
Слой модели представляет данные и бизнес-логику:
- `Note`: сущность заметки (id, title, duration, audioPath, serverId, и т.д.)
- `Location`: сопровождение Note для контекста записи
- `User`: локальное представление данных пользователя

### View
Слой представления отвечает за отображение пользовательского интерфейса. Примеры:
- `RecorderView`: главный CTA-экран записи
- `SaveSheetView`: экран для ввода названия, выбора папки и подтверждения сохранения записи
- `NotesListView`: список локальных заметок, поиск, сортировка, быстрые действия (шаринг PDF/аудио)
- `NoteDetailView`: экран заголовка, текста, длительности, местоположения заметки; действия экспорта
- **Custom компоненты UI:** многократно используемые представления SwiftUI

### ViewModel
Слой ViewModel управляет логикой представления:
- `RecorderViewModel`: логика записи, таймером и амплитудами эквалайзера
- `NotesListViewModel`: загрузка списка заметок, фильтрация/поиск/сортировка
- `NoteShareViewModel`: логика скачивания и шаринга
- **Проверка данных:** обеспечивание целостности данных
- **Управление состоянием:** обработка состояния UI

### Router
Централизованный объект навигации/маршрутизации. Управление:
- текущей вкладкой (например, .notes)
- переходами и модальными состояниями (лист шаринга, детали заметки, настройки)
- пример: RecorderStartView вызывает appRouter.setTab(to: .notes) по .onTap

### Services
Инкапсулирование работы с системой, сетью и хранилищем:
- `RecordsService`: загрузка PDF/аудио по serverId, выгрузка записей на бэкенд
- `AudioRecorderService`: запись аудио, имя файла и URL, поток амплитуд для эквалайзера
- `LocationService`: разрешения, текущая локация, обратное геокодирование (улица/город)
- `AuthorizationService`: авторизация, оперирование токенами через keychain
- **Вспомогательные:** LoadingOverlay - индикатор загрузки; Toast — уведомления

<h2 id="build">Сборка и запуск 🚀</h2>

1. Клонирование проекта
- git clone https://github.com/WoTRemboy/SmartRecorder
- Откройте SmartRecorder.xcodeproj в Xcode

2. Зависимости
- Используется Swift Package Manager (SPM) - автоматическое разрешение при открытии проекта
- В Xcode: File → Packages → Resolve Package Versions (если не произошло автоматически)

3. Настройка бэкенда (локально)
- Клонируйте бэкенд: git clone https://github.com/KingOfRaccoon/SmartDictophone
- Следуйте инструкциям README в репозитории бэкенда для запуска локального сервера
- По умолчанию рекомендуется поднимать на http://localhost:8888
- Убедитесь, что конечные точки для скачивания доступны

4. Сборка и запуск
- Выберите схему SmartRecorder и таргет (симулятор или подключённый девайс)
- Product → Run (Cmd+R)
- В случае ошибки подписи: зайти в Targets → Signing & Capabilities → изменить Bundle ID на произвольный

5. Диагностика и логи
- Используйте Console.app для просмотра OSLog
- При сетевых ошибках проверьте Docker Logs бэкенда и доступность эндпоинтов

<h2 id="requirements">Requirements ✅</h2>

- Xcode 26.0+
- Swift 5.9+
- iOS 26.0+
- Доступ к локальному бэкенду SmartDictophone
