# 🎤 VoiceTyper — Архитектура

## Идея

macOS-приложение в трее для голосового ввода текста.
Правый Cmd → аудиозапись → faster-whisper (large-v3) → вставка в буфер обмена.

## Компоненты

```
┌─────────────────────────────────┐     HTTP/JSON      ┌──────────────────────────┐
│         VoiceTyper.app          │ ◄───────────────► │   Сервер (78-й Mac M4)   │
│       (клиентский Mac)          │                     │    127.0.0.1:9001     │
│                                 │   POST /transcribe  │                          │
│  ┌─────────────────────────┐    │   (WAV → JSON)     │  ┌──────────────────┐    │
│  │ StatusBarApp (SwiftUI)  │    │                     │  │  faster-whisper  │    │
│  │   - MenuBar иконка      │    │                     │  │  (large-v3)      │    │
│  │   - SettingsView        │    │                     │  └────────┬─────────┘    │
│  │   - цвет: 🔴🟠⚪        │    │                     │           │               │
│  │                         │    │                     │  ┌────────▼─────────┐    │
│  │ HotKeyRecorder          │──┼─                     │  │  Ollama          │    │
│  │   - Правый Cmd          │    │                     │  │  Qwen 2.5 3B     │    │
│  │   - Старт/стоп          │    │                     │  │  (чистка,         │    │
│  │                         │    │                     │  │   отключена)     │    │
│  │ AudioRecorder           │    │                     │  └──────────────────┘    │
│  │   - AVAudioEngine       │    │                     │                          │
│  │   - WAV 16kHz 16bit     │    │                     │                          │
│  │   - Выбор устройства    │    │                     │                          │
│  │                         │    │                     │                          │
│  │ VoiceTyperClient        │    │                     │                          │
│  │ PasteManager            │    │                     │                          │
│  │   - AppleScript Cmd+V   │    │                     │                          │
│  │   - Fallback: ⌘V сам    │    │                     │                          │
│  └─────────────────────────┘    │                     └──────────────────────────┘
└─────────────────────────────────┘
```

## Сервер (78-й Mac Mini M4, 127.0.0.1)

### API

| Метод | Путь | Описание |
|--------|------|----------|
| GET | /status | Проверка здоровья |
| GET | /settings | Вернуть настройки |
| POST | /transcribe | Аудио → текст |

**POST /transcribe:**
- `multipart/form-data: audio` (WAV, 16kHz, 16bit, mono)
- `clean_llm: bool` (по умолч. false)
- `language: str` (auto/ru/en)

**Ответ:**
```json
{
  "raw": "распознанный текст",
  "cleaned": null,
  "language": "ru",
  "duration_ms": 3200,
  "model": "large-v3"
}
```

### Серверный стек

- Python 3 + FastAPI + Uvicorn
- faster-whisper large-v3 (CUDA/CoreML на M4)
- Ollama Qwen 2.5 3B (чистка, отключена по умолчанию)
- Запуск: `~/voicetyper-server/server/start.sh`

## Клиент (VoiceTyper.app)

### Статус-бар

- ⚪ mic.circle — готов
- 🔴 mic.circle.fill (красный) — запись
- 🟠 mic.circle.fill (оранжевый) — обработка

### Настройки

| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| Server Host | 127.0.0.1 | IP сервера |
| Server Port | 9001 | Порт |
| Whisper Model | large-v3 | small/medium/large-v3 |
| Clean with LLM | false | Чистка Ollama |
| Language | auto | auto/ru/en |

### Аудиозапись

- AVAudioEngine + AVAudioConverter
- Вход: выбор не-виртуального устройства
- Формат: WAV 16kHz 16bit mono
- Файл: временный, удаляется после отправки

### Вставка

1. Копирование в NSPasteboard.general
2. AppleScript: `keystroke "v" using command down`
3. Если нет Accessibility прав — уведомление "⌘V to paste"
4. Логи: `~/Desktop/voicetyper_debug.log`

## Поток выполнения

```
1. Правый Cmd (зажал) → 🔴 запись
2. Правый Cmd (отпустил) → 🟠 обработка
3. POST /transcribe → fastfer-whisper large-v3
4. Копирование в буфер обмена
5. AppleScript Cmd+V (если есть Accessibility права)
6. ⚪ готов
```

## Сборка

```
cd VoiceTyper
swift build -c debug
bash scripts/make_app.sh
cp -R VoiceTyper.app ~/Applications/
xattr -dr com.apple.quarantine ~/Applications/VoiceTyper.app
```

## Примечания

- macOS 26.5+ (Swift 6)
- Mac mini M4 (78-й) не имеет встроенного микрофона — нужна вебкамера/гарнитура
- Минимальный bundle ID: com.vklusov.VoiceTyper (права Accessibility не слетают)
- Подпись: ad-hoc + entitlements (микрофон, автоматизация)
