======================================================================
  EASY RED 2 - CAPTURE TIME MOD  v1.0
======================================================================

[ ENGLISH ]

Changes how long it takes to capture a zone in the official Easy Red 2
missions. Vanilla zones mostly take 30 seconds; this mod sets every zone
to the time you choose (default: 210 seconds = 3.5 minutes).

INSTALL / USE
  1. Extract this folder anywhere (for example into the Easy Red 2 folder).
  2. Open settings.ini and set CaptureTime (seconds, 1 - 3600).
  3. Close the game completely.
  4. Double-click Apply.bat.
  To change the time later: edit settings.ini, close the game, run Apply.bat again.

FILES
  Apply.bat     - applies the time in settings.ini
  Restore.bat   - puts every mission back to the original
  Status.bat    - shows the current capture time of every mission
  settings.ini  - your settings
  CaptureTimeMod.ps1 - the actual tool (plain text, you can read all of it)

GOOD TO KNOW
  - The first time you run Apply.bat, the original mission files are backed up
    to "<Easy Red 2 folder>\CaptureTimeMod_Backup". Do not delete this folder
    while the mod is applied - Restore.bat needs it.
  - After a game update or "Verify integrity of game files" in Steam, the missions
    go back to vanilla. Just run Apply.bat again.
  - Only official missions with capture zones are changed (192 missions).
    Defend/wave missions have no capture zones and are left untouched.
    Workshop missions are not changed.
  - Multiplayer: the capture time is decided by the host. Only the player
    who hosts the game needs this mod; other players can join with a vanilla game.
  - Uninstall: run Restore.bat, then delete this folder.
    (Steam > Easy Red 2 > Properties > Installed Files > Verify integrity
    also restores everything.)

SAFETY
  - No internet access, no admin rights, nothing is installed, no game code
    or .exe/.dll file is changed.
  - It only edits "Easy Red 2_Data\StreamingAssets\Missions\*\*.mer2" and only
    the 4-byte capture-time number of each zone. File sizes never change.
  - Every file is parsed structurally, patched, re-parsed and verified before
    it is written; anything unexpected is skipped and left untouched.
  - The .bat files only start Windows PowerShell with this one script.
    "-ExecutionPolicy Bypass" applies only to that single run.
  - No game files are included in this download - your own files are edited
    on your PC.


[ TURKCE ]

Resmi Easy Red 2 gorevlerinde bir bolgeyi ele gecirme suresini degistirir.
Orijinal bolgeler cogunlukla 30 saniyedir; bu mod tum bolgeleri sizin
sectiginiz sureye ayarlar (varsayilan: 210 saniye = 3,5 dakika).

KURULUM / KULLANIM
  1. Bu klasoru istediginiz yere cikarin (ornegin Easy Red 2 klasorunun icine).
  2. settings.ini dosyasini acip CaptureTime degerini yazin (saniye, 1 - 3600).
  3. Oyunu tamamen kapatin.
  4. Apply.bat'a cift tiklayin.
  Sureyi sonra degistirmek icin: settings.ini'yi duzenleyin, oyunu kapatin,
  Apply.bat'i tekrar calistirin.

DOSYALAR
  Apply.bat     - settings.ini'deki sureyi uygular
  Restore.bat   - tum gorevleri orijinal haline dondurur
  Status.bat    - her gorevin mevcut ele gecirme suresini gosterir
  settings.ini  - ayarlariniz
  CaptureTimeMod.ps1 - asil arac (duz metin, tamamini okuyabilirsiniz)

BILMENIZ GEREKENLER
  - Apply.bat ilk calistiginda orijinal gorev dosyalari
    "<Easy Red 2 klasoru>\CaptureTimeMod_Backup" klasorune yedeklenir.
    Mod uygulanmisken bu klasoru silmeyin - Restore.bat buna ihtiyac duyar.
  - Oyun guncellemesinden veya Steam'de "Oyun dosyalarinin butunlugunu dogrula"
    yapildiktan sonra gorevler orijinale doner. Apply.bat'i tekrar calistirin.
  - Sadece ele gecirme bolgesi olan resmi gorevler degisir (192 gorev).
    Savunma/dalga gorevlerinde bolge olmadigi icin dokunulmaz.
    Workshop gorevleri degismez.
  - Cok oyunculu: ele gecirme suresini sunucuyu kuran oyuncu belirler. Modun
    sadece sunucuyu kuran oyuncuda olmasi yeterlidir; digerleri modsuz katilabilir.
  - Kaldirma: Restore.bat'i calistirin, sonra bu klasoru silin.
    (Steam > Easy Red 2 > Ozellikler > Yuklu Dosyalar > Butunlugu dogrula
    da her seyi geri getirir.)

GUVENLIK
  - Internet baglantisi yok, yonetici izni gerekmez, hicbir sey kurulmaz,
    oyunun kodu veya .exe/.dll dosyalari degismez.
  - Sadece "Easy Red 2_Data\StreamingAssets\Missions\*\*.mer2" dosyalarinda,
    sadece her bolgenin 4 baytlik sure degerini degistirir. Dosya boyutu degismez.
  - Her dosya yapisal olarak okunur, degistirilir, tekrar okunup dogrulanir ve
    ancak ondan sonra yazilir; beklenmeyen bir durumda dosya atlanir ve
    oldugu gibi birakilir.
  - .bat dosyalari sadece Windows PowerShell ile bu tek scripti calistirir.
    "-ExecutionPolicy Bypass" yalnizca o calistirma icin gecerlidir.
  - Bu indirmede hicbir oyun dosyasi yoktur - kendi dosyalariniz kendi
    bilgisayarinizda duzenlenir.
