# v0.30 集氣與命中音效

生成方式：以 `scripts/generate_combat_audio_v30.py` 使用 NumPy、SciPy 與 Python wave 原創合成，固定種子可重現。未使用外部錄音、語音、旋律或第三方音樂。44.1kHz／16-bit／單聲道 PCM。這份紀錄是波形與頻譜檢查，沒有宣稱已做真人試聽。

| 檔案 | 時長 | 設計 | 功率頻譜重心 |
|---|---:|---|---:|
| `assets/v30/audio/charge_build.wav` | 0.78秒 | 布料與低中頻氣流逐漸聚集，避免尖銳電子高音 | 672.6Hz |
| `assets/v30/audio/charge_release.wav` | 0.48秒 | 厚重刀刃破風，低頻主體加短促刀鋒與氣流尾音 | 622.8Hz |
| `assets/v30/audio/impact_hit.wav` | 0.16秒 | 乾燥、圓潤、短促的接觸音，與揮刀風聲分離 | 887.1Hz |
| `assets/v30/audio/impact_heavy.wav` | 0.32秒 | 較硬的圓潤瞬態、低沉接觸與短共鳴 | 367.0Hz |

所有檔案峰值0.71997（小於0.75），頭尾4ms柔化且首尾樣本為0；5kHz以上功率小於0.001%。驗證包含聲道、取樣率、位元深度、樣本數、峰值與端點；完整數據位於 `assets/v30/audio/audio-validation.json`。

建議整合：蓄能聲開始一次播放；釋放聲在集氣攻擊打擊期開始時觸發；普通命中與集氣命中分別採用 impact_hit／impact_heavy。建議以戰鬥音效匯流排約-13dB起始混音，避免多個命中過度堆疊。整合由主代理處理。
