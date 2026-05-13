# VoiceTyper Client

macOS приложение в строке меню для голосового ввода текста.

## 🚀 Установка в Xcode

1. Открой Xcode → **File → New Project**
2. macOS → **App** → Next
3. Product Name: `VoiceTyper`, Interface: SwiftUI, Language: Swift
4. Удали сгенерированные файлы
5. Перетащи файлы из папки `VoiceTyper/` в проект
6. **Info.plist** — добавь:
   - `Privacy - Microphone Usage Description`: `Для записи голоса`
   - `Privacy - Accessibility Usage Description`: `Для вставки текста в активное окно`
7. **Signing & Capabilities** — включи:
   - Hardened Runtime → Resource Access → Audio Input
8. Собери (Cmd+B) и запусти (Cmd+R)

## Что уже внутри

| Файл | Описание |
|------|----------|
| `VoiceTyperApp.swift` | Точка входа, @main |
| `AppDelegate.swift` | Иконка в трее, хоткей, запись/стоп |
| `AudioRecorder.swift` | Запись WAV (16kHz, 16bit, mono) |
| `VoiceTyperClient.swift` | HTTP клиент для сервера |
| `PasteManager.swift` | Вставка текста через Cmd+V |
| `Settings.swift` | Модели данных |
| `SettingsView.swift` | UI настроек |
| `StatusBarView.swift` | Popover со статусом |

## Зависимости

Нет внешних зависимостей — всё на Foundation + AppKit + AVFoundation.
