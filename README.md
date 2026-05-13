# VoiceTyper 🎤

> macOS-приложение для голосового ввода текста. Хоткей → речь → текст → сразу в окно.

**VoiceTyper** слушает, распознаёт и печатает за тебя.  
Написан голосом для быстрого набора: идеи, заметки, ответы — всё, что удобнее сказать, чем напечатать.

## Как это работает

```
🎙️ Хоткей (Option+Space) → Аудиозапись → Whisper → (🛠️ LLM-чистка опционально) → Вставка в окно
```

- Нажал хоткей — говоришь  
- Отпустил — текст уже вставляется туда, где ты работал  
- Чистка в LLM (опционально) — расставляет пунктуацию, заглавные, формат

## Архитектура

```
┌──────────────────────────┐     HTTP/JSON      ┌──────────────────────────┐
│    VoiceTyper.app        │ ◄───────────────► │   VoiceTyper Server      │
│   (macOS, SwiftUI)       │                    │ (Python + FastAPI)       │
│                          │                    │                          │
│  StatusBar App           │                    │  faster-whisper (small)  │
│  HotKey (Option+Space)   │                    │  Ollama + Qwen 2.5 3B   │
│  Audio Recorder          │                    │                          │
│  Paste via A11y API      │                    │                          │
└──────────────────────────┘                    └──────────────────────────┘
```

### Клиент (скоро)
- Иконка в трее macOS
- Горячая клавиша (Option+Space)
- Запись → отправка на сервер → вставка в активное окно
- Настройки: модель Whisper, LLM-чистка, язык, хоткей

### Сервер (готов ✅)
- FastAPI на Python
- Транскрибация через [faster-whisper](https://github.com/SYSTRAN/faster-whisper)
- Опциональная чистка текста через [Ollama](https://ollama.com) + Qwen 2.5 3B
- Поддержка русского и английского

## Быстрый старт (сервер)

### 1. Установка зависимостей

```bash
# Python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Ollama (для LLM-чистки, опционально)
# https://ollama.com/download
ollama pull qwen2.5:3b
```

### 2. Запуск

```bash
# Убедись, что Ollama запущен
ollama serve &

# Запусти сервер
./server/start.sh
# или: python3 server/server.py
```

По умолчанию сервер слушает порт **9001**.

### 3. Проверка

```bash
curl http://localhost:9001/status
# → {"status":"ok","whisper_model":"small","ollama":"available"}
```

## API

### `GET /status`
Проверка здоровья сервера.

### `GET /settings`
Текущие настройки и доступные модели.

### `POST /transcribe`
Транскрибация аудио.

**Request:** `multipart/form-data`
| Поле | Тип | Описание |
|------|-----|----------|
| `audio` | File | WAV-файл (16kHz, 16bit, mono) |
| `clean_llm` | bool | Применить LLM-чистку |
| `language` | string | `"auto"`, `"ru"` или `"en"` |

**Response:**
```json
{
  "raw": "сырой транскрипт",
  "cleaned": "Чистый транскрипт (если clean_llm=true)",
  "language": "ru",
  "language_probability": 0.98,
  "duration_ms": 1200,
  "model": "small"
}
```

## Настройки сервера

| Переменная | По умолчанию | Описание |
|-----------|-------------|----------|
| порт (argv) | 9001 | Порт сервера |
| модель Whisper | small | tiny/base/small/medium/large-v3 |
| LLM-чистка | false | Вкл/выкл в запросе |

## Требования

- **macOS** (рекомендуется Apple Silicon)
- **Python 3.10+**
- **Ollama** (опционально, только для LLM-чистки)
- ~500 MB для модели Whisper small

## Roadmap

- [x] Сервер: транскрибация через faster-whisper
- [x] Сервер: опциональная LLM-чистка
- [ ] Клиент: SwiftUI приложение в трее
- [ ] Клиент: хоткей запись
- [ ] Клиент: вставка в активное окно
- [ ] Настройки: выбор модели в UI
- [ ] Lang auto-detect toggle
- [ ] Режим реального времени (streaming)

## Лицензия

MIT
