# Beschreibung
``` powershell
Get-ChildItem Cert:\CurrentUser\my -CodeSigningCert
$c=Get-ChildItem Cert:\CurrentUser\my\D95888D13D9175B6AA985DA8EAE71CE68A6E254E
Set-AuthenticodeSignature -FilePath "C:\Users\Michael.Lindner\Projekte\Modul01\modul01.ps1" -Certificate $c

```