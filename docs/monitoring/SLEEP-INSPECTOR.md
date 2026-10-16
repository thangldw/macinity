# Macinity Sleep Inspector contract

## English

### Scope

Sleep Inspector reads bounded OS sleep-prevention assertions through an explicit read-only system inspection. It links process identities where observable and distinguishes unavailable, partial and stale results. Refresh is an observation, not a request to alter sleep settings or terminate processes.

### Coverage and limits

Assertions explain observed prevention at the read time; they are not a complete historical wake diagnosis or proof that a particular app is faulty. No global Lock Screen changes, automatic unlock, fake input, kill, priority change or power-policy mutation is part of this workflow.

### Verification

Long-duration sensor tests encountered real sleep/wake transitions. Their wall duration and active engine duration must be distinguished.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## Tiếng Việt

### Scope

Sleep Inspector đọc bounded sleep-prevention assertions qua explicit read-only inspection. Link process identity nếu quan sát được, phân biệt unavailable/partial/stale. Refresh chỉ quan sát, không đổi sleep setting hay terminate process.

### Coverage and limits

Assertion giải thích prevention tại thời điểm đọc, không phải complete historical wake diagnosis hoặc proofappfaulty. Không đổi Lock Screen, auto-unlock, fake input, kill, priority hoặc power policy trong workflow này.

### Verification

Test sensor dài gặp sleep/wake thực; cần phân biệt wall duration với active engine duration.

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)

## 日本語

### Scope

Sleep Inspectorは明示read-only inspectionでbounded sleep-prevention assertionを読み、観測可能なprocess identityをリンク。Unavailable/partial/staleを区別。Refreshは観測でsleep設定変更やprocess停止ではありません。

### Coverage and limits

Assertionは読取時点のpreventionを説明し、完全なhistorical wake診断やapp故障の証明ではありません。Lock Screen変更、auto-unlock、fakeinput、kill、priority、power policy操作なし。

### Verification

長時間sensor testに実sleep/wakeがあったためwall durationとactive engine durationを区別します。

[User guide](../USER-GUIDE.md) · [Release readiness](../production/RELEASE-READINESS.md)
