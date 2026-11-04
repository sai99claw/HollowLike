Before generating code in a new session, read `.codex/MEMORY.md` and `.codex/skills/memory-adr-sync/SKILL.md`. Record persistent user rules using Context, Decision, and Status. Latest explicit decisions supersede older conflicting rules. Accepted design is not evidence of completed implementation.

## 提交與合併

每筆新的 commit 都必須有簡短標題及空一行後的內文。人與 AI 都遵守，包含修正、文件、合併及 squash commit。AI 提交前應根據實際的 staged diff 撰寫內文，逐項記錄：

- **功能與變更**：本次處理了哪些功能或問題、各自改了什麼。使用具體功能名，並列出主要檔案或模組，方便用 Git 歷史搜尋。
- **原因**：為什麼做這項變更，必要時附需求、issue 或前置提交。
- **驗證**：寫出實際做過的檢查及結果。尚未驗證的項目如實記錄。

合併前，先比對兩邊的 commit 內文和實際 diff。若同一功能兩邊都有改動，確認是重複實作還是互補，再決定如何合併，並在合併或 squash commit 的內文記錄處置。使用自動發布工具前，先建立符合本規則的 commit，避免工具代填通用訊息。
