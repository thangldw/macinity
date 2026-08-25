# Contributing to Toolbox

[English](#english) · [Tiếng Việt](#tiếng-việt) · [日本語](#日本語)

## English

### Workflow and change discipline

Open an issue for behavior or policy changes whose scope is not already agreed. Work on a focused branch, keep each commit reviewable, and use short imperative messages such as `feat: add conflict-safe restore`. Add a failing regression before implementation when practical, make the smallest source change, and update affected documentation in the same pull request.

Preserve Toolbox's local-first safety contract. Mutations require explicit foreground review, exact canonical targets, immediate revalidation, and Trash-backed recovery whenever macOS permits. Never broaden deletion with globs, unresolved variables, name-only matching, symlink escape, or inferred project artifacts. New process execution must use exact executable and argument allowlists. New network behavior requires an explicit privacy design and must not transmit scan or device data.

Do not commit build output, personal reports, credentials, signing identities, notarization material, or private sample data. Do not silently change release assets or convert historical records into current product claims.

### Required review evidence

Run from `apps/toolbox`:

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
```

Command Line Tools can run the smoke gates and release build; `swift test` requires full Xcode's XCTest module in this repository. A pull request must identify the user-visible behavior, safety/privacy impact, tests added or changed, exact commands and results, and any unavailable validation. GUI changes need before/after screenshots or a short recording, including relevant empty, error, confirmation, and reduced-coverage states. Release changes need immutable artifact, checksum, signing, notarization, architecture, and exact-run evidence without upgrading unknown evidence by inference.

### Localization

Tracked Toolbox Markdown must contain complete `## English`, `## Tiếng Việt`, and `## 日本語` sections in that order. English is canonical for commands, identifiers, paths, endpoints, tags, SHAs, and checksums; Vietnamese and Japanese must retain the same requirements and limitations rather than summarize them.

The shipped GUI supports English and Vietnamese. Add every new user-facing string to both localization resources, preserve exact UI labels where documentation refers to them, and run `./scripts/lint_localizations.swift`. Do not translate source identifiers, commands, filenames, URLs, bundle identifiers, or evidence values.

### Accessibility

New controls must be keyboard reachable, expose an understandable accessibility name, and preserve a visible focus state. Icon-only controls require a VoiceOver label. Do not rely on color alone for risk, status, or confirmation; keep text and symbols available. Verify readable contrast, text resizing, truncated localization, dialog order, and VoiceOver reading order for changed flows.

### Review scope

Reviewers check behavior against source and executable tests first, then workflow/run evidence, published release metadata, and documentation. A review does not treat a local build as signing/notarization evidence or a screenshot as proof of mutation safety. See [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md), [Privacy](PRIVACY.md), and [Security](SECURITY.md) before changing their contracts.

## Tiếng Việt

### Workflow và kỷ luật thay đổi

Mở issue cho thay đổi behavior hoặc policy chưa được thống nhất scope. Làm việc trên branch tập trung, giữ từng commit có thể review và dùng message mệnh lệnh ngắn như `feat: add conflict-safe restore`. Thêm regression đang fail trước implementation khi phù hợp, thực hiện thay đổi source nhỏ nhất và cập nhật tài liệu bị ảnh hưởng trong cùng pull request.

Giữ contract an toàn local-first của Toolbox. Mutation cần foreground review rõ ràng, canonical target chính xác, revalidation ngay trước thao tác và recovery qua Trash khi macOS cho phép. Không mở rộng phạm vi xóa bằng glob, biến chưa resolve, name-only matching, symlink escape hoặc artifact project suy luận. Process execution mới phải dùng executable/argument allowlist chính xác. Network behavior mới cần privacy design rõ ràng và không được truyền scan hoặc device data.

Không commit build output, report cá nhân, credential, signing identity, notarization material hoặc sample data riêng tư. Không âm thầm thay release asset hoặc biến historical record thành current product claim.

### Evidence bắt buộc khi review

Chạy từ `apps/toolbox`:

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
```

Command Line Tools chạy được smoke gate và release build; `swift test` trong repository này cần module XCTest của full Xcode. Pull request phải nêu user-visible behavior, tác động safety/privacy, test thêm hoặc sửa, command/result chính xác và validation chưa thể chạy. Thay đổi GUI cần screenshot trước/sau hoặc recording ngắn, gồm state empty, error, confirmation và reduced coverage liên quan. Thay đổi release cần evidence về immutable artifact, checksum, signing, notarization, architecture và exact run; không suy luận evidence chưa biết thành pass.

### Localization

Markdown được track của Toolbox phải có đầy đủ section `## English`, `## Tiếng Việt`, `## 日本語` theo thứ tự đó. English là canonical cho command, identifier, path, endpoint, tag, SHA và checksum; bản Vietnamese/Japanese phải giữ cùng requirement/limitation thay vì tóm tắt.

GUI được ship hỗ trợ English và Vietnamese. Thêm mọi user-facing string mới vào cả hai localization resource, giữ UI label chính xác khi tài liệu tham chiếu và chạy `./scripts/lint_localizations.swift`. Không dịch source identifier, command, filename, URL, bundle identifier hoặc evidence value.

### Accessibility

Control mới phải dùng được bằng keyboard, có accessibility name dễ hiểu và giữ visible focus state. Control chỉ có icon cần VoiceOver label. Không chỉ dùng màu để thể hiện risk, status hoặc confirmation; phải giữ text và symbol. Xác minh contrast dễ đọc, text resizing, localization bị cắt, thứ tự dialog và VoiceOver reading order cho flow thay đổi.

### Phạm vi review

Reviewer đối chiếu behavior với source và executable test trước, sau đó mới tới workflow/run evidence, published release metadata và documentation. Review không coi local build là evidence signing/notarization hoặc screenshot là proof về mutation safety. Đọc [Architecture](docs/ARCHITECTURE.md), [Operations](docs/OPERATIONS.md), [Privacy](PRIVACY.md) và [Security](SECURITY.md) trước khi đổi contract tương ứng.

## 日本語

### Workflow と change discipline

Scope が未合意の behavior または policy change は issue を作成します。Focused branch で作業し、各 commit を review 可能に保ち、`feat: add conflict-safe restore` のような短い imperative message を使います。可能な場合は implementation 前に failing regression を追加し、最小の source change を行い、影響する documentation を同じ pull request で更新します。

Toolbox の local-first safety contract を保持します。Mutation には明示的 foreground review、exact canonical target、action 直前の revalidation、macOS が許す場合の Trash-backed recovery が必要です。Glob、未解決変数、name-only matching、symlink escape、推測した project artifact で削除範囲を広げません。新しい process execution は exact executable/argument allowlist を使います。新しい network behavior は明示的 privacy design を必要とし、scan/device data を送信してはいけません。

Build output、personal report、credential、signing identity、notarization material、private sample data を commit しません。Release asset を黙って置換したり、historical record を current product claim に変えたりしません。

### Review に必要な evidence

`apps/toolbox` から実行します。

```bash
swift format lint --recursive --parallel Sources Tests Package.swift
swift test
./scripts/test_core.sh
./scripts/test_storage.sh
./scripts/test_changes.sh
./scripts/test_app.sh
./scripts/lint_localizations.swift
swift build -c release
./scripts/build_app.sh
```

Command Line Tools では smoke gate と release build を実行できます。この repository の `swift test` には full Xcode の XCTest module が必要です。Pull request は user-visible behavior、safety/privacy impact、追加・変更 test、正確な command/result、実行できない validation を記載します。GUI change には before/after screenshot または短い recording を付け、関連する empty、error、confirmation、reduced-coverage state を含めます。Release change には immutable artifact、checksum、signing、notarization、architecture、exact-run evidence が必要で、unknown evidence を推測で pass にしません。

### Localization

追跡済み Toolbox Markdown は `## English`、`## Tiếng Việt`、`## 日本語` の完全な section をこの順序で持ちます。Command、identifier、path、endpoint、tag、SHA、checksum は English を canonical とし、Vietnamese/Japanese は summary ではなく同じ requirement と limitation を保持します。

公開 GUI は English と Vietnamese をサポートします。新しい user-facing string は両方の localization resource に追加し、documentation が参照する exact UI label を保持して `./scripts/lint_localizations.swift` を実行します。Source identifier、command、filename、URL、bundle identifier、evidence value は翻訳しません。

### Accessibility

新しい control は keyboard 操作可能で、理解できる accessibility name と visible focus state を持つ必要があります。Icon-only control には VoiceOver label が必要です。Risk、status、confirmation を色だけで伝えず、text と symbol も保持します。変更 flow について readable contrast、text resizing、localization truncation、dialog order、VoiceOver reading order を検証します。

### Review scope

Reviewer は source と executable test、workflow/run evidence、published release metadata、documentation の順で behavior を確認します。Local build を signing/notarization evidence と扱わず、screenshot を mutation safety の proof と扱いません。Contract を変更する前に [Architecture](docs/ARCHITECTURE.md)、[Operations](docs/OPERATIONS.md)、[Privacy](PRIVACY.md)、[Security](SECURITY.md) を参照してください。
