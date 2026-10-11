<#
  Easy Red 2 - Capture Time Mod  v1.0

  Sets the capture time (secureTime) of every capture zone in the official
  Easy Red 2 missions to the value in settings.ini.

  What this script does / does NOT do:
    - Reads and edits ONLY "<game>\Easy Red 2_Data\StreamingAssets\Missions\*\*.mer2"
    - Before the first change, copies each original file to "<game>\CaptureTimeMod_Backup"
    - Changes only the 4-byte secureTime number of each capture zone (file size never changes)
    - Every edited file is re-parsed and verified before it is written
    - No internet access, no admin rights, no registry writes, no downloads, nothing installed
    - Reads the Steam registry key HKCU\Software\Valve\Steam only to locate the game folder

  Usage:  CaptureTimeMod.ps1 apply | restore | status
#>
param(
    [ValidateSet('apply', 'restore', 'status')]
    [string]$Command = 'status'
)

$ErrorActionPreference = 'Stop'
$ModVersion   = '1.0'
$ModDir       = $PSScriptRoot
$ConfigPath   = Join-Path $ModDir 'settings.ini'
$GameExeName  = 'Easy Red 2'
$BackupName   = 'CaptureTimeMod_Backup'
$MinSeconds   = 1
$MaxSeconds   = 3600

Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace Er2CaptureTimeMod
{
    // Minimal reader for .NET BinaryFormatter (MS-NRBF) streams. It walks every
    // record so that the secureTime field is located by structure, never by
    // guessing byte patterns.
    public static class Nrbf
    {
        const string TargetClass = "MissionEditorBattleData.MissionEditorPhaseObjectiveArea";
        const string TargetField = "secureTime";
        const int MaxDepth = 256;

        sealed class ClassInfo
        {
            public string Name;
            public string[] Members;
            public byte[] BinaryTypes;
            public byte[] PrimitiveTypes;
        }

        sealed class Parser
        {
            readonly byte[] d;
            int p;
            int pendingNulls;
            int depth;
            readonly Dictionary<int, ClassInfo> classes = new Dictionary<int, ClassInfo>();
            public readonly List<int> Hits = new List<int>();

            public Parser(byte[] data) { d = data; }

            Exception Bad(string msg) { return new InvalidDataException(msg + " (offset " + p + ")"); }
            void Need(long n) { if (n < 0 || p + n > d.Length) throw Bad("Unexpected end of file"); }
            byte U8() { Need(1); return d[p++]; }
            int I32() { Need(4); int v = BitConverter.ToInt32(d, p); p += 4; return v; }
            int Count() { int v = I32(); if (v < 0 || v > d.Length) throw Bad("Invalid count"); return v; }
            void Skip(int n) { Need(n); p += n; }

            int VarLen()
            {
                int n = 0;
                for (int i = 0; i < 5; i++)
                {
                    byte b = U8();
                    n |= (b & 0x7F) << (7 * i);
                    if ((b & 0x80) == 0) return n;
                }
                throw Bad("Invalid string length");
            }

            string Str()
            {
                int n = VarLen();
                Need(n);
                string s = Encoding.UTF8.GetString(d, p, n);
                p += n;
                return s;
            }

            void Prim(byte t)
            {
                switch (t)
                {
                    case 1: case 2: case 10: Skip(1); return;
                    case 7: case 14: Skip(2); return;
                    case 8: case 11: case 15: Skip(4); return;
                    case 6: case 9: case 12: case 13: case 16: Skip(8); return;
                    case 3:
                        {
                            byte b = U8();
                            Skip(b < 0x80 ? 0 : b < 0xE0 ? 1 : b < 0xF0 ? 2 : 3);
                            return;
                        }
                    case 5: case 18: Str(); return;
                    default: throw Bad("Unknown primitive type " + t);
                }
            }

            void Values(ClassInfo c)
            {
                bool target = c.Name == TargetClass;
                for (int i = 0; i < c.Members.Length; i++)
                {
                    if (c.BinaryTypes[i] == 0)
                    {
                        if (target && c.Members[i] == TargetField)
                        {
                            if (c.PrimitiveTypes[i] != 11) throw Bad("secureTime is not a float");
                            Hits.Add(p);
                        }
                        Prim(c.PrimitiveTypes[i]);
                    }
                    else
                    {
                        Record();
                    }
                }
            }

            void Items(long n, byte binaryType, byte primType)
            {
                for (long i = 0; i < n; i++)
                {
                    if (binaryType == 0) Prim(primType);
                    else Record();
                }
            }

            // Returns true on MessageEnd.
            public bool Record()
            {
                if (pendingNulls > 0) { pendingNulls--; return false; }
                if (++depth > MaxDepth) throw Bad("Nesting too deep");
                try
                {
                    byte rt = U8();
                    switch (rt)
                    {
                        case 0: Skip(16); break;                       // SerializationHeader
                        case 1:                                         // ClassWithId
                            {
                                int oid = I32();
                                int meta = I32();
                                ClassInfo c;
                                if (!classes.TryGetValue(meta, out c)) throw Bad("Unknown class reference");
                                classes[oid] = c;
                                Values(c);
                                break;
                            }
                        case 2: case 3: throw Bad("Untyped class records are not supported");
                        case 4: case 5:                                 // (System)ClassWithMembersAndTypes
                            {
                                int oid = I32();
                                ClassInfo c = new ClassInfo();
                                c.Name = Str();
                                int n = Count();
                                c.Members = new string[n];
                                c.BinaryTypes = new byte[n];
                                c.PrimitiveTypes = new byte[n];
                                for (int i = 0; i < n; i++) c.Members[i] = Str();
                                for (int i = 0; i < n; i++) c.BinaryTypes[i] = U8();
                                for (int i = 0; i < n; i++)
                                {
                                    byte bt = c.BinaryTypes[i];
                                    if (bt == 0 || bt == 7) c.PrimitiveTypes[i] = U8();
                                    else if (bt == 3) Str();
                                    else if (bt == 4) { Str(); I32(); }
                                    else if (bt > 7) throw Bad("Unknown binary type " + bt);
                                }
                                if (rt == 5) I32();                     // library id
                                classes[oid] = c;
                                Values(c);
                                break;
                            }
                        case 6: I32(); Str(); break;                    // BinaryObjectString
                        case 7:                                         // BinaryArray
                            {
                                I32();
                                byte arrayType = U8();
                                int rank = Count();
                                long total = 1;
                                for (int i = 0; i < rank; i++)
                                {
                                    total *= Count();
                                    if (total > d.Length) throw Bad("Array too large");
                                }
                                if (arrayType >= 3 && arrayType <= 5) Skip(4 * rank);
                                byte bt = U8();
                                byte pt = 0;
                                if (bt == 0 || bt == 7) pt = U8();
                                else if (bt == 3) Str();
                                else if (bt == 4) { Str(); I32(); }
                                Items(total, bt, pt);
                                break;
                            }
                        case 8: Prim(U8()); break;                      // MemberPrimitiveTyped
                        case 9: I32(); break;                           // MemberReference
                        case 10: break;                                 // ObjectNull
                        case 11: return true;                           // MessageEnd
                        case 12: I32(); Str(); break;                   // BinaryLibrary
                        case 13: pendingNulls = Math.Max(0, U8() - 1); break;
                        case 14: pendingNulls = Math.Max(0, Count() - 1); break;
                        case 15:                                        // ArraySinglePrimitive
                            {
                                I32();
                                int n = Count();
                                byte pt = U8();
                                Items(n, 0, pt);
                                break;
                            }
                        case 16: { I32(); Items(Count(), 2, 0); break; } // ArraySingleObject
                        case 17: { I32(); Items(Count(), 1, 0); break; } // ArraySingleString
                        default: throw Bad("Unknown record type " + rt);
                    }
                    return false;
                }
                finally { depth--; }
            }

            public void Run()
            {
                while (p < d.Length)
                    if (Record()) return;
                throw Bad("MessageEnd not found");
            }
        }

        public static int[] FindSecureTimeOffsets(byte[] data)
        {
            Parser parser = new Parser(data);
            parser.Run();
            return parser.Hits.ToArray();
        }

        public static float ReadFloat(byte[] data, int offset)
        {
            return BitConverter.ToSingle(data, offset);
        }

        // Returns a patched copy. Throws if the result does not verify.
        public static byte[] Patch(byte[] original, float seconds)
        {
            int[] offsets = FindSecureTimeOffsets(original);
            byte[] result = (byte[])original.Clone();
            byte[] value = BitConverter.GetBytes(seconds);
            bool[] allowed = new bool[original.Length];
            foreach (int off in offsets)
            {
                Buffer.BlockCopy(value, 0, result, off, 4);
                for (int i = 0; i < 4; i++) allowed[off + i] = true;
            }

            int[] check = FindSecureTimeOffsets(result);
            if (check.Length != offsets.Length) throw new InvalidDataException("Verification failed: zone count changed");
            for (int i = 0; i < check.Length; i++)
            {
                if (check[i] != offsets[i] || ReadFloat(result, check[i]) != seconds)
                    throw new InvalidDataException("Verification failed: wrong value after patch");
            }
            for (int i = 0; i < result.Length; i++)
            {
                if (result[i] != original[i] && !allowed[i])
                    throw new InvalidDataException("Verification failed: unexpected byte changed");
            }
            return result;
        }
    }
}
'@

# ---------------------------------------------------------------- helpers

function Stop-WithError([string]$Message) {
    Write-Host ''
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Read-Settings {
    if (-not (Test-Path -LiteralPath $ConfigPath)) { Stop-WithError "settings.ini was not found next to the script." }
    $settings = @{}
    foreach ($line in [IO.File]::ReadAllLines($ConfigPath, [Text.Encoding]::UTF8)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t[0] -in ';', '#', '[') { continue }
        $i = $t.IndexOf('=')
        if ($i -lt 1) { continue }
        $settings[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim().Trim('"')
    }
    return $settings
}

function Get-CaptureSeconds($settings) {
    $raw = [string]$settings['CaptureTime']
    $value = 0.0
    $ok = [double]::TryParse(($raw -replace ',', '.'), [Globalization.NumberStyles]::Float,
                             [Globalization.CultureInfo]::InvariantCulture, [ref]$value)
    if (-not $ok) { Stop-WithError "CaptureTime in settings.ini is not a number: '$raw'" }
    if ($value -lt $MinSeconds -or $value -gt $MaxSeconds) {
        Stop-WithError "CaptureTime must be between $MinSeconds and $MaxSeconds seconds (current: $raw)."
    }
    return [single]$value
}

function Format-Seconds([single]$s) { return $s.ToString([Globalization.CultureInfo]::InvariantCulture) }

function Test-GameDir([string]$dir) {
    return $dir -and (Test-Path -LiteralPath (Join-Path $dir 'Easy Red 2_Data\StreamingAssets\Missions'))
}

function Find-GameDir($settings) {
    $custom = [string]$settings['GamePath']
    if ($custom) {
        if (Test-GameDir $custom) { return (Resolve-Path -LiteralPath $custom).Path }
        Stop-WithError "GamePath in settings.ini is not an Easy Red 2 folder: $custom"
    }
    # Mod folder placed inside (or below) the game folder
    $dir = $ModDir
    for ($i = 0; $i -lt 4 -and $dir; $i++) {
        if (Test-GameDir $dir) { return $dir }
        $dir = Split-Path -Parent $dir
    }
    # Steam libraries
    $libraries = @()
    try {
        $steam = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath
        $libraries += $steam
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) {
                $libraries += ($m.Groups[1].Value -replace '\\\\', '\')
            }
        }
    } catch { }
    foreach ($lib in $libraries) {
        $candidate = Join-Path $lib 'steamapps\common\Easy Red 2'
        if (Test-GameDir $candidate) { return $candidate }
    }
    Stop-WithError 'Easy Red 2 folder not found. Write it into GamePath in settings.ini.'
}

$sha256 = [Security.Cryptography.SHA256]::Create()
function Get-Hash([byte[]]$bytes) { return ([BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace '-', '') }

function Write-FileSafe([string]$path, [byte[]]$bytes) {
    $tmp = "$path.ctm_tmp"
    try {
        [IO.File]::WriteAllBytes($tmp, $bytes)
        if (Test-Path -LiteralPath $path) { [IO.File]::Replace($tmp, $path, [NullString]::Value) }
        else { [IO.File]::Move($tmp, $path) }
    } finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    }
}

# Manifest: one line per edited file -> relative path, original SHA-256, patched SHA-256
function Read-Manifest([string]$path) {
    $map = @{}
    if (Test-Path -LiteralPath $path) {
        foreach ($line in [IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8)) {
            $parts = $line.Split("`t")
            if ($parts.Length -ne 3) { continue }
            # Only accept "<mission folder>\<file>.mer2" and real SHA-256 values, so a damaged or
            # edited manifest can never make the script write outside the Missions/backup folders.
            $rel = $parts[0]
            if ($rel -notmatch '^[^\\/:*?"<>|]+\\[^\\/:*?"<>|]+\.mer2$' -or $rel -match '(^|\\)\.\.') { continue }
            if ($parts[1] -notmatch '^[0-9A-F]{64}$' -or $parts[2] -notmatch '^[0-9A-F]{64}$') { continue }
            $map[$rel] = @{ Original = $parts[1]; Patched = $parts[2] }
        }
    }
    return $map
}

function Save-Manifest([string]$path, $map) {
    $lines = foreach ($k in ($map.Keys | Sort-Object)) { "$k`t$($map[$k].Original)`t$($map[$k].Patched)" }
    $tmp = "$path.tmp"
    [IO.File]::WriteAllLines($tmp, [string[]]@($lines), (New-Object Text.UTF8Encoding $false))
    if (Test-Path -LiteralPath $path) { [IO.File]::Replace($tmp, $path, [NullString]::Value) } else { [IO.File]::Move($tmp, $path) }
}

function Get-MissionFiles([string]$missionsDir) {
    Get-ChildItem -LiteralPath $missionsDir -Directory | Sort-Object Name | ForEach-Object {
        Get-ChildItem -LiteralPath $_.FullName -File -Filter '*.mer2' | Where-Object { $_.Extension -eq '.mer2' }
    }
}

function Assert-GameClosed {
    if (Get-Process -Name $GameExeName -ErrorAction SilentlyContinue) {
        Stop-WithError 'Easy Red 2 is running. Close the game completely and try again.'
    }
}

function Get-RelativePath([string]$base, [string]$full) { return $full.Substring($base.Length).TrimStart('\') }

# ---------------------------------------------------------------- commands

$settings    = Read-Settings
$gameDir     = Find-GameDir $settings
$missionsDir = Join-Path $gameDir 'Easy Red 2_Data\StreamingAssets\Missions'
$backupDir   = Join-Path $gameDir $BackupName
$manifestPth = Join-Path $backupDir 'manifest.tsv'

Write-Host "Easy Red 2 - Capture Time Mod v$ModVersion"
Write-Host "Game folder : $gameDir"

switch ($Command) {

    'status' {
        $seconds = Get-CaptureSeconds $settings
        Write-Host "Setting     : CaptureTime = $(Format-Seconds $seconds) s"
        Write-Host ''
        $manifest = Read-Manifest $manifestPth
        $zones = 0; $missions = 0; $failed = 0
        foreach ($f in Get-MissionFiles $missionsDir) {
            $bytes = [IO.File]::ReadAllBytes($f.FullName)
            try { $offs = [Er2CaptureTimeMod.Nrbf]::FindSecureTimeOffsets($bytes) }
            catch { Write-Host ("  {0,-42} could not be read: {1}" -f $f.Directory.Name, $_.Exception.GetBaseException().Message) -ForegroundColor Yellow; $failed++; continue }
            if ($offs.Length -eq 0) { continue }
            $values = $offs | ForEach-Object { [math]::Round([Er2CaptureTimeMod.Nrbf]::ReadFloat($bytes, $_), 1) } | Sort-Object -Unique |
                      ForEach-Object { $_.ToString([Globalization.CultureInfo]::InvariantCulture) }
            $rel = Get-RelativePath $missionsDir $f.FullName
            $tag = if ($manifest.ContainsKey($rel) -and $manifest[$rel].Patched -eq (Get-Hash $bytes)) { 'modded  ' } else { 'original' }
            Write-Host ("  {0,-42} {1}  zones={2,-3} seconds={3}" -f $f.Directory.Name, $tag, $offs.Length, ($values -join ', '))
            $zones += $offs.Length; $missions++
        }
        Write-Host ''
        Write-Host "$missions missions, $zones capture zones. Unreadable: $failed"
    }

    'apply' {
        Assert-GameClosed
        $seconds = Get-CaptureSeconds $settings
        Write-Host "Setting     : CaptureTime = $(Format-Seconds $seconds) s"
        Write-Host ''
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        $manifest = Read-Manifest $manifestPth
        $changed = 0; $already = 0; $zones = 0; $failed = 0

        foreach ($f in Get-MissionFiles $missionsDir) {
            $rel = Get-RelativePath $missionsDir $f.FullName
            try {
                $current = [IO.File]::ReadAllBytes($f.FullName)
                $currentHash = Get-Hash $current
                $entry = $manifest[$rel]
                $backupFile = Join-Path $backupDir $rel

                # Always start from the untouched original
                if ($entry -and $currentHash -eq $entry.Patched) {
                    $original = [IO.File]::ReadAllBytes($backupFile)
                    if ((Get-Hash $original) -ne $entry.Original) { throw 'backup file is damaged' }
                } else {
                    # Original file (first run, or the game was updated / verified by Steam)
                    $original = $current
                }
                $originalHash = Get-Hash $original

                $offsets = [Er2CaptureTimeMod.Nrbf]::FindSecureTimeOffsets($original)
                if ($offsets.Length -eq 0) { continue }   # no capture zones (e.g. defend missions)

                $patched = [Er2CaptureTimeMod.Nrbf]::Patch($original, $seconds)
                $patchedHash = Get-Hash $patched
                $zones += $offsets.Length

                if ($patchedHash -eq $currentHash) { $already++; continue }

                # 1) backup, 2) manifest, 3) mission file - so an interruption never loses the original
                if (-not ($entry -and $entry.Original -eq $originalHash -and (Test-Path -LiteralPath $backupFile))) {
                    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backupFile) | Out-Null
                    Write-FileSafe $backupFile $original
                }
                $manifest[$rel] = @{ Original = $originalHash; Patched = $patchedHash }
                Save-Manifest $manifestPth $manifest
                Write-FileSafe $f.FullName $patched
                $changed++
            } catch {
                Write-Host ("  SKIPPED {0}: {1}" -f $rel, $_.Exception.GetBaseException().Message) -ForegroundColor Yellow
                $failed++
            }
        }
        Write-Host "Done. $changed missions updated, $already already had this value, $zones capture zones = $(Format-Seconds $seconds) s."
        if ($failed) { Write-Host "$failed files were skipped (left unchanged)." -ForegroundColor Yellow }
        Write-Host "Backups: $backupDir"
    }

    'restore' {
        Assert-GameClosed
        $manifest = Read-Manifest $manifestPth
        if ($manifest.Count -eq 0) { Write-Host 'Nothing to restore - no backups found.'; break }
        $restored = 0; $untouched = 0; $failed = 0
        foreach ($rel in @($manifest.Keys)) {
            $entry = $manifest[$rel]
            $path = Join-Path $missionsDir $rel
            try {
                if (-not (Test-Path -LiteralPath $path)) { $untouched++; continue }
                $currentHash = Get-Hash ([IO.File]::ReadAllBytes($path))
                if ($currentHash -eq $entry.Patched) {
                    $original = [IO.File]::ReadAllBytes((Join-Path $backupDir $rel))
                    if ((Get-Hash $original) -ne $entry.Original) { throw 'backup file is damaged' }
                    Write-FileSafe $path $original
                    $restored++
                } else {
                    $untouched++   # already original, or replaced by a game update
                }
            } catch {
                Write-Host ("  FAILED {0}: {1}" -f $rel, $_.Exception.GetBaseException().Message) -ForegroundColor Yellow
                $failed++
            }
        }
        if ($failed -eq 0) {
            Remove-Item -LiteralPath $backupDir -Recurse -Force
            Write-Host "Done. $restored missions restored to original ($untouched were already original). Backup folder removed."
        } else {
            Write-Host "$restored restored, $failed failed. Backup folder kept: $backupDir" -ForegroundColor Yellow
        }
    }
}
