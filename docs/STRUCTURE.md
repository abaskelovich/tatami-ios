# Структура Tatami iOS

В монорепозитории весь клиент находится в `Tatami-iOS/`. При переносе через
`git subtree split --prefix=Tatami-iOS` содержимое этого каталога становится
корнем отдельного приватного репозитория. Все команды ниже выполняются из этого корня.

```text
App/                         SwiftUI: запись, история, настройки, диагностика
  Assets.xcassets/            AccentColor и пустой слот AppIcon 1024×1024
Packages/TatamiCore/
  Package.swift              Swift 6 tools, Swift 5 language mode
  Sources/TatamiCore/         модели, state machine, порты, очередь, JSON store, fakes
  Tests/TatamiCoreTests/      XCTest без Apple UI/audio frameworks
Tests/                       hosted unit test демонстрационного сценария
UITests/                     smoke test запуска
project.yml                  исходный XcodeGen spec; .xcodeproj не хранится в Git
scripts/select-simulator.sh  выбор iPhone в новейшем доступном iOS runtime
.github/workflows/ios-ci.yml Linux core tests → simulator tests → unsigned IPA
docs/device-testing.md       установка на iPhone с Windows
```

## Текущий срез

iPhone, iOS 18.0+, bundle ID `com.tatami.assistant`, версия 0.1.0 (1).
Целевое устройство — iPhone 14 Plus с iOS 18.6. Экран записи использует
`FakeAudioCapture`: таймер и маленький silent WAV, без доступа к микрофону.
Продолжительность в модели — время демонстрационной сессии; WAV содержит один
тихий sample и не представляет эту длительность. `FakeTranscriber` возвращает
демонстрационный текст и умеет имитировать заданное число ошибок. Реального
сетевого адаптера и API-интеграции в этом срезе нет.

`TatamiCore` использует только Foundation. Очередь — actor с одним владельцем
store: сначала durable insert, затем сохранение uploading и вызов transcriber.
Готовые к попытке задания обрабатываются по времени записи; ожидающие backoff
не блокируют следующие задания. Ошибка сохраняет recording, attempt и deadline;
задержка 2, 4, 8… секунд, максимум 300 секунд. Повтор после прерванной загрузки
использует прежний idempotency key. Повторный enqueue не сбрасывает состояние.
API удаления нет. `FileJobStore` атомарно заменяет JSON через Foundation
`Data.write(.atomic)` и не перезаписывает повреждённое хранилище пустым.
Одновременные независимые очереди/процессы на одном файле не поддерживаются.

Данные демо хранятся в Application Support/Tatami: `jobs.json`, `Recordings/`.
Сбой сохранения оставляет файл и ссылку в памяти для повторной попытки;
восстановление orphan audio после завершения процесса между записью WAV и
enqueue ещё не реализовано. Реальный crash-safe capture/journal относится к
следующему срезу. Очередь запускается при активной сцене раз в секунду; фоновых
задач и настоящей фоновой записи пока нет.

Диагностика показывает только состояния, счётчики, категорию последней ошибки
и фазу сцены. Тексты, аудио, пути и идентификаторы не логируются. Не добавлять
entitlements, App Groups, push, iCloud или keychain-sharing в этот срез.

## Сборка и проверка

На текущей Windows-машине нет Swift, Xcode и Docker. Компиляция выполняется
в GitHub Actions **после** публикации отдельного репозитория владельцем:

1. Linux, `swift:6.1`: `cd Packages/TatamiCore && swift test`.
2. `macos-26`: Xcode 26.x, XcodeGen **2.43.0**, `xcodegen generate`.
3. `xcodebuild test -scheme Tatami -destination 'id=<available-iphone-udid>'`
   с `CODE_SIGNING_ALLOWED=NO`; hosted unit test и launch UI test.
4. Release archive для `generic/platform=iOS`, без подписи; упаковка
   `Payload/Tatami.app` в `build/Tatami-unsigned.ipa`.

Artifact `Tatami-unsigned` хранится 14 дней; `Tatami-test-results` (.xcresult)
— 7 дней, загружается и при ошибке тестов, если файл успел появиться.
Secrets не нужны. Generated project, build outputs, IPA и SwiftPM cache
исключены в `.gitignore`. Пустой AppIcon допустим для этого bootstrap;
публикация в App Store не входит в задачу.

Spec использует local package, application и два test bundle, shared scheme
по [документации XcodeGen 2.43.0](https://github.com/yonaskolb/XcodeGen/blob/2.43.0/Docs/ProjectSpec.md).
Команды XcodeGen/xcodebuild также можно повторить на Mac из корня клиента.

## Установка без Mac

Скачайте artifact, распакуйте IPA и передайте его Sideloadly на Windows.
Sideloadly подписывает приложение личным бесплатным Apple ID и устанавливает
его на подключённый iPhone; unsigned IPA напрямую не запускается.
Пошагово: [device-testing.md](device-testing.md).
