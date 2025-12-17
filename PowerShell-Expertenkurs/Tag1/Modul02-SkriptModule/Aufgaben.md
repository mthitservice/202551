# Modul 02: Skript-Module erstellen - Übungsaufgaben

## Übersicht
**Dauer:** ca. 60 Minuten  
**Schwierigkeit:** Fortgeschritten

---

## Aufgabe 1: Einfaches Modul erstellen (20 Minuten)

### Ihre Aufgabe
Erstellen Sie ein Modul namens **"NetworkTools"** mit folgenden Anforderungen:

1. **Modul-Ordner:** `C:\Temp\NetworkTools\`

2. **Öffentliche Funktionen (3 Stück):**
   
   - `Test-PortConnection`
     - Parameter: `-ComputerName`, `-Port`, `-Timeout` (Standard: 3 Sekunden)
     - Prüft ob ein TCP-Port erreichbar ist
     - Gibt PSCustomObject mit ComputerName, Port, IsOpen, ResponseTimeMs zurück
   
   - `Get-PublicIPAddress`
     - Keine Parameter
     - Holt die öffentliche IP-Adresse über einen Web-Service (z.B. api.ipify.org)
     - Gibt PSCustomObject mit IPAddress und CheckTime zurück
   
   - `Get-DNSInfo`
     - Parameter: `-DomainName` (Pflicht)
     - Löst DNS-Namen auf
     - Gibt PSCustomObject mit DomainName, IPAddresses, RecordType zurück

3. **Private Hilfsfunktion (1 Stück):**
   
   - `Format-Timestamp`
     - Gibt aktuellen Zeitstempel formatiert zurück
     - Wird von den öffentlichen Funktionen genutzt

4. **Anforderungen:**
   - Alle öffentlichen Funktionen nutzen `[CmdletBinding()]`
   - Die private Funktion darf NICHT exportiert werden
   - Nutzen Sie `Export-ModuleMember` am Ende der .psm1

### Erwartete Nutzung
```powershell
Import-Module C:\Temp\NetworkTools\NetworkTools.psm1
Test-PortConnection -ComputerName "google.com" -Port 443
Get-PublicIPAddress
Get-DNSInfo -DomainName "microsoft.com"
```

---

## Aufgabe 2: Module Manifest erstellen (15 Minuten)

### Ihre Aufgabe
Erstellen Sie für Ihr NetworkTools-Modul ein vollständiges Manifest:

1. **Manifest-Datei:** `NetworkTools.psd1`

2. **Pflichtfelder:**
   - ModuleVersion: 1.0.0
   - Author: Ihr Name
   - Description: Aussagekräftige Beschreibung
   - PowerShellVersion: 5.1
   - RootModule: NetworkTools.psm1

3. **Export-Kontrolle:**
   - FunctionsToExport: Nur die 3 öffentlichen Funktionen
   - CmdletsToExport: Leer (@())
   - AliasesToExport: Leer (@())

4. **Optional aber empfohlen:**
   - Tags für die Suche
   - ProjectUri (kann fiktiv sein)
   - GUID (automatisch generieren)

### Validierung
```powershell
# Manifest testen
Test-ModuleManifest -Path "C:\Temp\NetworkTools\NetworkTools.psd1"

# Modul über Manifest laden
Import-Module "C:\Temp\NetworkTools\NetworkTools.psd1" -Verbose
```

---

## Aufgabe 3: Fortgeschrittenes Modul mit Dateistruktur (25 Minuten)

### Ihre Aufgabe
Erstellen Sie ein professionell strukturiertes Modul namens **"ProcessManager"**:

1. **Ordnerstruktur erstellen:**
```
C:\Temp\ProcessManager\
├── ProcessManager.psd1
├── ProcessManager.psm1
├── Public\
│   ├── Get-ProcessReport.ps1
│   ├── Stop-ProcessByMemory.ps1
│   └── Get-ProcessTree.ps1
├── Private\
│   └── ConvertTo-SizeString.ps1
└── Data\
    └── config.json
```

2. **Private Funktion - ConvertTo-SizeString.ps1:**
   - Konvertiert Bytes in lesbare Größen (KB, MB, GB)
   - Wird intern von anderen Funktionen verwendet

3. **Öffentliche Funktionen:**

   **Get-ProcessReport.ps1:**
   - Parameter: `-Name` (Wildcard), `-MinMemoryMB` (Standard: 0)
   - Zeigt: Name, Id, CPU, MemoryMB (formatiert), StartTime
   - Sortiert nach Memory absteigend

   **Stop-ProcessByMemory.ps1:**
   - Parameter: `-ThresholdMB` (Pflicht), `-Exclude` (String-Array)
   - Nutzt SupportsShouldProcess für -WhatIf/-Confirm
   - Stoppt Prozesse die mehr als ThresholdMB verwenden
   - Schließt angegebene Prozesse aus

   **Get-ProcessTree.ps1:**
   - Parameter: `-ProcessId` oder `-Name`
   - Zeigt Parent- und Child-Prozesse
   - Nutzt Parameter Sets

4. **Haupt .psm1 Datei:**
   - Lädt alle .ps1 Dateien per Dot-Sourcing
   - Exportiert nur Public-Funktionen

5. **config.json:**
   - Enthält Default-Werte (z.B. DefaultThresholdMB: 100)
   - Wird beim Modulstart geladen

### Erwartete Nutzung
```powershell
Import-Module C:\Temp\ProcessManager -Verbose

Get-ProcessReport -MinMemoryMB 50 | Format-Table
Stop-ProcessByMemory -ThresholdMB 500 -Exclude "explorer","dwm" -WhatIf
Get-ProcessTree -Name "pwsh"
```

---

## Bonusaufgabe: Modul mit Klassen (Optional, +15 Minuten)

### Ihre Aufgabe
Erweitern Sie ProcessManager um eine PowerShell-Klasse:

1. **Classes\ProcessInfo.ps1:**
```powershell
class ProcessInfo {
    [string]$Name
    [int]$Id
    [double]$MemoryMB
    [datetime]$StartTime
    
    ProcessInfo([System.Diagnostics.Process]$process) {
        # Konstruktor implementieren
    }
    
    [string] GetSummary() {
        # Zusammenfassung zurückgeben
    }
    
    static [ProcessInfo[]] GetTopByMemory([int]$count) {
        # Statische Methode implementieren
    }
}
```

2. Die Klasse soll in Get-ProcessReport verwendet werden können

---

## Abgabe-Checkliste

### Aufgabe 1
- [ ] NetworkTools.psm1 erstellt
- [ ] 3 öffentliche Funktionen implementiert
- [ ] 1 private Funktion implementiert
- [ ] Export-ModuleMember korrekt verwendet
- [ ] Modul lässt sich importieren und nutzen

### Aufgabe 2
- [ ] NetworkTools.psd1 erstellt
- [ ] Test-ModuleManifest erfolgreich
- [ ] Modul über .psd1 importierbar
- [ ] Nur öffentliche Funktionen exportiert

### Aufgabe 3
- [ ] Ordnerstruktur erstellt
- [ ] Alle .ps1 Dateien implementiert
- [ ] Dot-Sourcing in .psm1 funktioniert
- [ ] config.json wird geladen
- [ ] SupportsShouldProcess funktioniert

---

## Tipps

1. **Testen Sie schrittweise:** Erstellen Sie erst eine Funktion, testen Sie, dann die nächste
2. **Dot-Sourcing Pattern:**
   ```powershell
   $Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
   foreach ($file in $Public) { . $file.FullName }
   ```
3. **Modul neu laden:**
   ```powershell
   Remove-Module ModuleName -Force -ErrorAction SilentlyContinue
   Import-Module .\ModuleName -Force -Verbose
   ```
4. **Debugging:** Nutzen Sie `Write-Verbose` in allen Funktionen
