# Contributing / Đóng góp / コントリビューション

[Tiếng Việt](#vi) · [English](#en) · [日本語](#ja)

<a id="vi"></a>

## Tiếng Việt

Cảm ơn bạn muốn đóng góp cho Thang Toolbox.

1. Tạo issue mô tả lỗi hoặc đề xuất trước những thay đổi lớn.
2. Tạo branch ngắn gọn từ `main`.
3. Không đưa dữ liệu cá nhân, cache thật hoặc thông tin máy người dùng vào test fixture.
4. Chạy test của ứng dụng bị thay đổi trước khi mở Pull Request.
5. Giải thích rõ mọi thao tác filesystem, quyền truy cập và khả năng khôi phục.

### Kiểm tra local

Diskora:

```bash
cd apps/diskora
./scripts/test_core.sh
swift build
```

Changeora:

```bash
cd apps/changeora
./scripts/test_core.sh
swift build
```

Pull Request liên quan đến xóa dữ liệu phải có test cho giới hạn đường dẫn và lỗi quyền truy cập. Thay đổi Changeora phải giữ pipeline read-only, trừ khi một thiết kế destructive mới được thảo luận và phê duyệt riêng.

### Sử dụng GitHub Actions tiết kiệm

- CI không tự chạy khi push trực tiếp vào `main`.
- CI chỉ chạy cho Pull Request có thay đổi ứng dụng tương ứng, hoặc khi được kích hoạt thủ công.
- Commit mới trong cùng Pull Request sẽ hủy lượt CI cũ đang chạy.
- Hãy chạy smoke test và `swift build` local trước khi mở Pull Request.

---

<a id="en"></a>

## English

Thank you for contributing to Thang Toolbox.

1. Open an issue describing a bug or proposal before making a large change.
2. Create a short-lived branch from `main`.
3. Never include personal data, real caches, or user machine information in test fixtures.
4. Run the tests for every affected application before opening a Pull Request.
5. Clearly explain filesystem operations, required permissions, and recovery behavior.

### Local verification

Diskora:

```bash
cd apps/diskora
./scripts/test_core.sh
swift build
```

Changeora:

```bash
cd apps/changeora
./scripts/test_core.sh
swift build
```

A Pull Request that deletes data must test path boundaries and permission failures. Changeora changes must preserve its read-only pipeline unless a new destructive design has been discussed and approved separately.

### Conserving GitHub Actions usage

- CI does not run automatically on direct pushes to `main`.
- CI runs only for Pull Requests that affect the corresponding application, or when manually dispatched.
- A new commit in the same Pull Request cancels the older in-progress run.
- Run smoke tests and `swift build` locally before opening a Pull Request.

---

<a id="ja"></a>

## 日本語

Thang Toolbox へのコントリビューションにご協力いただきありがとうございます。

1. 大きな変更を行う前に、バグや提案を説明する Issue を作成してください。
2. `main` から短期間使用するブランチを作成してください。
3. テスト fixture に個人データ、実際のキャッシュ、ユーザー端末の情報を含めないでください。
4. Pull Request を作成する前に、変更した各アプリケーションのテストを実行してください。
5. ファイルシステム操作、必要な権限、復元方法を明確に説明してください。

### ローカル検証

Diskora:

```bash
cd apps/diskora
./scripts/test_core.sh
swift build
```

Changeora:

```bash
cd apps/changeora
./scripts/test_core.sh
swift build
```

データを削除する Pull Request には、パス境界と権限エラーのテストが必要です。Changeora は、新しい破壊的設計が別途議論・承認されない限り、read-only パイプラインを維持してください。

### GitHub Actions 使用量の削減

- `main` への直接 push では CI を自動実行しません。
- 対象アプリケーションに変更がある Pull Request、または手動実行時のみ CI が動作します。
- 同じ Pull Request に新しい commit が追加されると、実行中の古い CI はキャンセルされます。
- Pull Request を作成する前に、ローカルで smoke test と `swift build` を実行してください。
