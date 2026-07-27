# 旅行規劃與紀錄工具

一個純前端的旅行工具：行前準備、行李分人打包、藥品管理、每日行程與 Google Maps 導航、天氣預報、支出記帳、遊記與影音紀錄。

**沒有伺服器、沒有資料庫、沒有帳號。** 所有資料只存在使用者自己的瀏覽器（localStorage），不會上傳到任何地方。

---

## 檔案清單

| 檔案 | 用途 |
|---|---|
| `index.html` | 工具本體（單檔，包含所有 CSS 與 JS） |
| `manifest.webmanifest` | 讓手機可以「加入主畫面」變成 App |
| `sw.js` | 離線快取，第二次之後沒網路也能開 |
| `icon.svg` / `icon-192.png` / `icon-512.png` / `icon-512-maskable.png` | 圖示 |
| `.nojekyll` | 讓 GitHub Pages 不要用 Jekyll 處理檔案（必要，別刪） |
| `README.md` | 這份說明（不影響網站運作） |

**這些檔案要放在同一層目錄**，不要分資料夾。

---

## 發佈到 GitHub Pages

### 第一次上架

1. 到 <https://github.com> 註冊 / 登入。
2. 右上角 **+ → New repository**。
   - **Repository name** 填一個好記的英文名，例如 `travel-kit`
   - 選 **Public**
   - 其他不用勾，按 **Create repository**
3. 進入剛建立的 repository，點 **Add file → Upload files**。
4. 把上面清單的檔案**全部**拖進去。
   - `.nojekyll` 是隱藏檔。Mac 在 Finder 按 `Cmd + Shift + .` 可以顯示隱藏檔；Windows 在檔案總管勾選「隱藏的項目」。
   - 如果真的拖不進去，可以改用網頁上的 **Add file → Create new file**，檔名輸入 `.nojekyll`，內容留空，按 Commit。
5. 下方按 **Commit changes**。
6. 上方 **Settings → Pages**（左側選單）。
   - **Source** 選 `Deploy from a branch`
   - **Branch** 選 `main`、資料夾選 `/ (root)`，按 **Save**
7. 等 1～3 分鐘，重新整理該頁，最上方會出現網址：

   ```
   https://你的帳號.github.io/travel-kit/
   ```

   這就是可以分享給大家的網址。

### 之後要更新

改好新的 `index.html` 之後：

1. 進入 repository，點進 `index.html`
2. 右上角鉛筆圖示 **Edit**（或直接 **Add file → Upload files** 覆蓋上傳）
3. 貼上新內容 → **Commit changes**
4. 約 1 分鐘後生效

> **重要**：因為有離線快取，更新後請把 `sw.js` 裡的
> `const VERSION = 'v1';` 改成 `'v2'`、`'v3'`…
> 使用者下次連上網才會拿到新版。不改的話他們可能一直看到舊版。

---

## 給使用者的說明（可以直接貼給朋友）

- **網址打開就能用**，不用註冊、不用安裝。
- 資料存在自己的手機／電腦裡，**別人看不到，我們也看不到**。
- 換裝置或清除瀏覽資料就會不見 → 記得定期按右上角 **「匯出全部」** 下載備份檔。
- 要把行程傳給同行者：按 **「匯出這趟」**，把 `.json` 檔傳給對方，對方按 **「匯入」**。
- 手機加到主畫面：
  - **iPhone (Safari)**：分享鍵 → 加入主畫面
  - **Android (Chrome)**：右上角 ⋮ → 安裝應用程式 / 加到主畫面
- 加到主畫面後，**沒網路也能開**（天氣與地圖需要網路）。

---

## 需要注意的事

- **無痕／隱私模式**下瀏覽器可能不允許儲存，工具會在右上角顯示「無法自動儲存」，這時請務必用匯出備份。
- **Safari** 若使用者超過 7 天沒開這個網站，可能會清掉 localStorage（ITP 政策）。長期資料請以匯出檔為準。
- 天氣資料來自 [Open-Meteo](https://open-meteo.com/)（免費、免金鑰、非商業使用免授權）；匯率來自 [Frankfurter](https://frankfurter.app/)。兩者都直接由使用者的瀏覽器呼叫，不經過任何中介伺服器。
- 藥品與健康相關內容僅為一般性提醒，**不構成醫療建議**。

---

## 自訂

想改工具名稱、預設清單或配色，全部都在 `index.html` 裡：

| 想改什麼 | 找什麼關鍵字 |
|---|---|
| 網站標題 | `<title>` 與 `brandTitle` |
| 配色 | 檔案開頭的 `:root{ --accent: ... }` |
| 預設藥品 | `function defaultMeds` |
| 預設行李清單 | `function defaultLuggage` |
| 預設行前待辦 | `function defaultPrep` |
| 預設緊急資訊卡 | `function defaultEmergency` |
| 支出分類 | 開頭的 `const CATS` |
| 遊記字數上限 | `const JMAX = 1500` |
