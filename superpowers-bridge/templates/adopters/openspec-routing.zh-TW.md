<!-- Workflow routing 規則(adopter 用)。install.sh 會把本檔(去掉 HTML 註解)複製到 .claude/rules/openspec-routing.md,Claude Code 啟動時自動載入。 -->
<!-- 要在目標 repo 客製 routing,編輯其 .claude/rules/openspec-routing.md。 -->
<!-- v1.5.0 對齊:openspec v1.5.0 命令集為 propose/apply/archive/explore/sync(無 new/ff/continue/verify)。 -->

## 變更工作流(Claude Code 啟動先讀)

本 repo 採用 [`superpowers-bridge`](https://github.com/AllenMuu/openspec-superpowers/tree/main/superpowers-bridge) 作為**預設** workflow schema,銜接 OpenSpec(做什麼)與 Superpowers(怎麼做:brainstorming、writing-plans、git-worktrees、subagent-driven-development、TDD、code-review)。整合規則(語言、artifact 路徑、PRECHECK)以該 bridge README 為準;以下是給 Claude 的 routing 指引。

**預設 schema = `superpowers-bridge`**(設於 `openspec/config.yaml`)。因此 `/opsx:propose` 預設走完整聚合流程:`brainstorm -> proposal -> design -> specs -> tasks -> plan -> [apply] -> verify -> retrospective`。較輕量的變更可對 `openspec new change` 傳 `--schema spec-driven` 退回。小修(bug/typo/config)直接 PR,不開 change。

### 入口分流

| 你看到的觸發 | 應該怎麼做 |
|---|---|
| 使用者以 narrative 開「設計討論 / 腦力激盪」 | 先 verbal `superpowers:brainstorming`,**不**寫到 `docs/superpowers/specs/`;對話收斂後依下方 5 條判準升級到 `/opsx:propose` |
| 使用者直接呼叫 `/opsx:propose` | 走 schema 既定流程;artifact instruction 在每步注入(預設 schema = superpowers-bridge) |
| 使用者明確說 bug fix / typo / config 微調 / 文件更新 | 直接 PR,**不**建 change(見下方 skip 規則) |
| 已經在某個 change 中 | 用 `/opsx:apply`(worktree + subagent-driven-development)或 `/opsx:archive` 推進;`/opsx:explore` 檢視、`/opsx:sync` 把 specs 併回主線 |

> v1.5.0 命令集:`propose / apply / archive / explore / sync`。本版本**沒有** `/opsx:new` / `/opsx:ff` / `/opsx:continue` / `/opsx:verify`。

### 何時**不**走 opsx(直接 PR)

| 情境 | 直接 PR? |
|---|---|
| 新功能 / 新 capability / 架構變更 / breaking change | ❌ 要走 opsx |
| Bug fix(不變更合約)/ 測試補寫 / linter 規則 / 非破壞性升級 / typo / 文件 / config 值微調 | ✅ 直接 PR |

原則:**流程儀式跟風險成正比**。動到對外合約 / schema / 跨系統介接 / 合規邊界 -> opsx;其他 -> 直接 PR。

### Verbal brainstorm 升級到 opsx 的 5 條判準

5 條**全滿足**才升級(任一缺則繼續 brainstorm,不寫到 `docs/superpowers/specs/`):

1. **Scope 鎖定** -- 一句話講清「包含/不包含什麼」
2. **主要設計分歧已收斂** -- 替代方案選過,剩下 TBD 有明確 owner 與影響面
3. **跨系統依賴盤點過** -- 對方就緒 / 暫 mock / 真未知,三選一講得清
4. **驗收條件可陳述** -- 具體 pass 條件(例:`./mvnw clean verify` 通過 + N 個成果)
5. **對話進入收斂** -- 最近幾輪在 confirm 不在發散

全滿足 -> 主動建議使用者「要不要 `/opsx:propose`?」,使用者 ack 後落地。永遠不要自動觸發。

### Front-door 反模式(別做)

- 讓 brainstorming 寫到 `docs/superpowers/specs/`
- 讓 writing-plans 寫到 `docs/superpowers/plans/`
- TBD 沒收斂就升級到 opsx
- 對 bug fix / typo 也建 change

詳細見 [superpowers-bridge README §進入與離開的判斷](https://github.com/AllenMuu/openspec-superpowers/blob/main/superpowers-bridge/README.zh-TW.md#進入與離開的判斷entry--exit-gates)。
