# ER2 Capture Time Mod

Unofficial fan mod for **Easy Red 2**, not affiliated with Corvostudio.

Changes how long it takes to capture a zone in the official Easy Red 2 missions. Vanilla zones mostly take 30 seconds; this tool sets every zone to the time you choose (default: **210 seconds = 3.5 minutes**).

*[Türkçe açıklama aşağıda.](#türkçe)*

## How it works

The official missions are stored as `.mer2` files. Each capture zone has a `secureTime` value. The tool reads every mission file structurally, changes only that 4-byte number in each capture zone, verifies the result, and writes it back. File sizes never change.

- No game code, no DLL injection, no mod loader. Only mission data files are edited.
- The original files are backed up before the first change and can be restored with one click.
- Works for every official mission on your PC, including DLC missions you own.
- Multiplayer: the capture time is decided by the host. Only the player who hosts needs the mod.

## Use

1. Download the files (Code → Download ZIP, or the zip in Releases) and extract them anywhere.
2. Open `settings.ini` and set `CaptureTime` (seconds, 1–3600).
3. Close the game completely.
4. Double-click `Apply.bat`.

| File | What it does |
|---|---|
| `Apply.bat` | Applies the time in `settings.ini` |
| `Restore.bat` | Puts every mission back to the original |
| `Status.bat` | Shows the current capture time of every mission |
| `settings.ini` | Your settings |
| `CaptureTimeMod.ps1` | The tool itself (plain text PowerShell, you can read all of it) |

The game folder is found automatically through Steam; if not, set `GamePath` in `settings.ini`.

## Good to know

- Backups go to `<Easy Red 2 folder>\CaptureTimeMod_Backup`. Do not delete it while the mod is applied.
- After a game update or "Verify integrity of game files" the missions go back to vanilla. Just run `Apply.bat` again.
- Workshop missions are not changed.
- No internet access, no admin rights, nothing is installed. The `.bat` files only start Windows PowerShell with this one script (`-ExecutionPolicy Bypass` applies to that single run).
- No game files are included in this repository; your own files are edited on your PC.
- The Easy Red 2 EULA restricts modifying the game. Use at your own risk.

---

## Türkçe

**Easy Red 2** için resmi olmayan bir hayran modu; Corvostudio ile bağlantısı yoktur.

Resmi görevlerde bir bölgeyi ele geçirme süresini değiştirir. Orijinal bölgeler çoğunlukla 30 saniyedir; bu araç bütün bölgeleri seçtiğin süreye ayarlar (varsayılan: **210 saniye = 3,5 dakika**).

**Kullanım:**
1. Dosyaları indir (Code → Download ZIP ya da Releases'teki zip) ve istediğin yere çıkar.
2. `settings.ini` dosyasındaki `CaptureTime` değerini yaz (saniye, 1–3600).
3. Oyunu tamamen kapat.
4. `Apply.bat`'a çift tıkla.

Geri almak için `Restore.bat`, mevcut süreleri görmek için `Status.bat`.

**Bilmen gerekenler:**
- Oyun kodu değişmez, mod yükleyici kullanılmaz; sadece görev veri dosyaları düzenlenir.
- Orijinal dosyalar ilk değişiklikten önce yedeklenir.
- Çok oyunculuda süreyi sunucuyu kuran oyuncu belirler; modun sadece onda olması yeterli.
- Oyun güncellemesi ya da Steam doğrulamasından sonra `Apply.bat`'ı tekrar çalıştır.
- Easy Red 2 sözleşmesi oyunun değiştirilmesini kısıtlıyor; kullanım kendi sorumluluğundadır.
