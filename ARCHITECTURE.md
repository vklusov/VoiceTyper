# 🎤 VoiceTyper — Архитектура

## Идея

macOS-приложение в трее для голосового ввода текста. Хоткей → аудиозапись → Whisper → (опросional LLM-чистка) → вставка в активное окно.

## Компоненты

```
┌─────────────────────────────────┐     HTTP/JSON      ┌──────────────────────────┐
│         VoiceTyper.app          │ ◄───────────────► │   Сервер (78-й Mac M4)   │
│       (клиентский Mac)          │                     │    127.0.0.1:9001     │
│                                 │   POST /transcribe  │                          │
│  ┌─────────────────────────┐    │   (WAV → JSON)     │  ┌──────────────────┐    │
│  │ StatusBarApp (SwiftUI)  │    │                     │  │  whisper-cpp     │    │
│  │   - MenuBar иконка      │    │                     │  │  (small/medium/   │    │
│  │   - SettingsView        │    │                     │  │   large)          │    │
│  │                         │    │                     │  └────────┬─────────┘    │
│  │ HotKeyRecorder          │──┼─                     │           │               │
│  │   - Option+Space        │    │                     │  ┌────────▼─────────┐    │
│  │   - Старт/стоп записи   │    │                     │  │  Ollama          │    │
│  │                         │    │                     │  │  Qwen 2.5 3B     │    │
│  │ AudioRecorder           │    │                     │  │  (чистка,        │    │
│  │   - Запись через AVCapture│   │                     │  │  опционально)    │    │
│  │   - WAV 16kHz 16bit     │    │                     │  └──────────────────┘    │
│  │                         │    │                     │                          │
│  │ HTTPClient              │    │                     │                          │
│  │ PasteManager            │    │                     │                          │
│  │   - Accessibility API   │    │                     │                          │
│  │   - Вставка в окно      │    │                     │                          │
│  └─────────────────────────┘    │                     └──────────────────────────┘
└─────────────────────────────────┘
```

## Сервер (78-й Mac Mini M4, 127.0.0.1)

### API Endpoints

| Method | Path | Описание |
|--------|------|----------|
| GET | /status | Проверка здоровья сервера |
| POST | /transcribe | Аудио → транскрипт |
| GET | /settings | Вернуть текущие настройки моделей |
| POST | /settings | Изменить модель/параметры |

### POST /transcribe

**Request:**
- `multipart/form-data` с полем `audio` (WAV, 16kHz, 16bit, mono)
- Доп. поле `clean_llm: bool` — нужна ли LLM-чистка

**Response:**
```json
{
  "raw": "сырои транскрипт от виспера",
  "cleaned": "Сырой транскрипт от Whisper.",
  "language": "ru",
  "duration_ms": 3200,
  "model": "small"
}
```

### Сборка whisper-cpp
- Репозиторий: https://github.com/ggerganov/whisper.cpp
- Сборка: `make -j` с поддержкой CoreML (на M4)
- Модели: `ggml-small.bin`, `ggml-medium.bin`, `ggml-large-v3.bin`
- Запуск: HTTP-сервер режим (whisper.cpp встроенный server)

### Ollama
- Модель: `qwen2.5:3b` (или `qwen2.5:7b` если хватит)
- Prompt для чистки:
  ```
  Исправь пунктуацию, заглавные буквы и форматирование в тексте.
  Сохрани все слова, не меняй смысл. Язык текста: {language}.
  
  Текст: {raw_transcript}
  ```

## Клиент (VoiceTyper.app)

### Статус-бар меню
- 🎤 — иконка приложения
- "Start recording" / "Stop recording"
- "Settings..."
- "Quit"

### Настройки (SettingsView)
| Параметр | Тип | По умолчанию | Описание |
|----------|-----|-------------|----------|
| Server Host | String | 127.0.0.1 | IP сервера |
| Server Port | Int | 9001 | Порт сервера |
| HotKey | KeyCombo | Option+Space | Хоткей записи |
| Whisper Model | Picker | small | small / medium / large |
| Clean with LLM | Toggle | true | Галочка "Проводить дополнительную чистку в LLM" |
| Language | Picker | auto | auto / ru / en |

### Аудиозапись
- Формат: WAV, 16kHz, 16bit, mono
- Библиотека: AVCaptureAudio or AudioQueue Services
- Временный файл: `/tmp/voicetyper_recording.wav`

### Вставка в окно
- Через Accessibility API (AXUIElementCopyAttributeValue)
- Эмуляция вставки текста через Cmd+V (после помещения в буфер)
- Или через `CGEventPost` с последовательностью клавиш

## Поток выполнения

### Базовый (без LLM)
```
1. Option+Space (зажал) → начало аудиозаписи
2. Option+Space (отпустил) → стоп, WAV готов
3. POST /transcribe → сервер → Whisper
4. Сервер → сырой текст
5. Вставка в активное окно
```

### С LLM-чисткой
```
1-3. То же самое
4. Сервер → Whisper → сырой текст
5. Ollama Qwen: чистка текста
6. Сервер → чистый текст
7. Вставка в активное окно
```

## Решения (13.05.2026)

- ✅ Аудиоформат: WAV (16kHz, 16bit, mono)
- ✅ LLM-чистка: настраиваемая галочка в UI
- ✅ Вставка: сразу в активное окно (Accessibility API)
- ✅ Язык: автоопределение Whisper с ручным выбором в настройках
- ✅ Модели Whisper: выбор small/medium/large в настройках
