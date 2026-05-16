# 🎤 VoiceTyper

Голосовой ввод текста на macOS. Push-to-talk: правый Cmd → говорить → распознавание → вставка.

## Как это работает

1. Нажать и держать **правый Cmd** → 🔴 запись
2. Отпустить → 🟠 faster-whisper large-v3 распознаёт
3. Текст в буфере обмена + уведомление
4. Если есть Accessibility права — вставляется автоматически (Cmd+V)
5. Если нет — уведомление "⌘V to paste" — нажми ⌘V сам

## Установка

### 1. Сервер (78-й Mac Mini, 127.0.0.1)

```bash
# Установка зависимостей
ssh server
python3 -m venv ~/voicetyper-server/venv
source ~/voicetyper-server/venv/bin/activate
pip install -r ~/voicetyper-server/requirements.txt

# Запуск
bash ~/voicetyper-server/server/start.sh
# Сервер на порту 9001
```

Сервер автоматически загрузит faster-whisper large-v3 при первом запросе (~3 GB).

### 2. Клиент (любой Mac)

```bash
# Клонирование
git clone https://github.com/vklusov/VoiceTyper.git
cd VoiceTyper

# Сборка
swift build -c debug

# Упаковка в .app и подпись
bash scripts/make_app.sh

# Установка
cp -R VoiceTyper.app ~/Applications/
xattr -dr com.apple.quarantine ~/Applications/VoiceTyper.app
open ~/Applications/VoiceTyper.app
```

### 3. Права доступа (однократно)

- **Микрофон:** System Settings → Privacy → Microphone → VoiceTyper
- **Accessibility (для автовставки):** System Settings → Privacy → Accessibility → VoiceTyper
- **Уведомления:** разрешить при первом запуске

## Быстрая пересборка

```bash
cd VoiceTyper
swift build -c debug
bash scripts/make_app.sh
rm -rf ~/Applications/VoiceTyper.app
cp -R VoiceTyper.app ~/Applications/
xattr -dr com.apple.quarantine ~/Applications/VoiceTyper.app
open ~/Applications/VoiceTyper.app
```

## Требования

- **macOS 26.5+** (Swift 6)
- **Python 3.9+** на сервере
- **faster-whisper** (загружается автоматически при первом запросе)
- Микрофон (в Mac mini нет встроенного — используйте вебкамеру или гарнитуру)

## Настройки

Настройки доступны через иконку в трее → правый клик → Settings:

| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| Server Host | 127.0.0.1 | IP сервера |
| Server Port | 9001 | Порт сервера |
| Whisper Model | large-v3 | small / medium / large-v3 |
| Clean with LLM | выкл | Чистка через Ollama Qwen 2.5 |
| Language | auto | Авто / Русский / English |

## Известные ограничения

- **Mac mini M4** не имеет встроенного микрофона — используйте USB-гарнитуру или вебкамеру
- Quality распознавания зависит от микрофона: вебкамера C920 даёт посредственный результат
- SuperWhisper использует собственные fine-tuned модели и пост-обработку — VoiceTyper использует стоковый faster-whisper
- Автовставка требует Accessibility прав

## Структура проекта

```
VoiceTyper/
├── Package.swift                   # SPM
├── Sources/VoiceTyper/
│   ├── VoiceTyperApp.swift        # @main
│   ├── AppDelegate.swift          # Логика, хоткей, состояния
│   ├── AudioRecorder.swift        # Запись через AVAudioEngine
│   ├── VoiceTyperClient.swift     # HTTP-клиент к серверу
│   ├── PasteManager.swift         # Копирование + вставка
│   ├── VTConfig.swift             # Настройки
│   ├── StatusBarView.swift        # Менюбар
│   └── SettingsView.swift         # Настройки UI
├── server/
│   └── server.py                  # FastAPI + faster-whisper
├── scripts/
│   ├── make_app.sh                # Упаковка .app
│   └── entitle_and_sign.sh        # Подпись (устар.)
├── VoiceTyper.entitlements        # Entitlements
├── service/                       # launchd plist (бета)
└── ARCHITECTURE.md
```

## Лицензия

MIT
