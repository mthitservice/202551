function Get-AdminApiHeaders {
    Param (
        $apiUrl,
        [Alias("Credentials")]
        [pscredential]$c
    )
        # .Net Object und Funktion deklarieren und laden wenn nicht vorhanden
        if(-not ('ITrustACertificatePolicy' -as [type]))
        {
        Add-Type @"        
using System.Net;
using System.Security.Cryptography.X509Certificates;

public class ITrustACertificatePolicy : ICertificatePolicy
{
    public ITrustACertificatePolicy() { }
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert, WebRequest request, int problem)
    {
        return true;
    }
}
"@
           }
# Instanziierung
[System.Net.ServicePointManager]::CertificatePolicy= New-Object ITrustACertificatePolicy
# Web Request

$iisAdminRequest=Invoke-WebRequest -Uri "$apiUrl/security/api-keys" -SessionVariable session  -Credential $c
# Token organisieren
$xsrfTokenHeader=$iisAdminRequest.Headers."XSRF-TOKEN"
$xsfrTokenHash=@{}
$xsfrTokenHash."XSRF-TOKEN"=$xsrfTokenHeader
#$xsfrTokenHash
# Mit dem Token API Keys abrufen
$iisAdminRequest2=Invoke-WebRequest  -Uri "$apiUrl/security/api-keys"   -Headers $xsfrTokenHash -Method Post  -ContentType "application/json" -WebSession $session -Body '{"expires_on":""}'
#$iisAdminRequest2
# Als Json ausgeben
$content=ConvertFrom-Json ([System.Text.Encoding]::UTF8.GetString($iisAdminRequest2.content))
$at=$content.access_token
$ath =@{}
$ath."Access-Token"="Bearer $at"
$ath."Accept"="application/hal+json"

return $ath


}

## Aufruf
$u=Get-Credential
$x=Get-AdminApiHeaders -apiUrl "https://localhost:55539" -Credentials $u
Write-Output -PSObject $x

# Nutzen des Tokens für einen administrativen Zugriff auf die iis Admin API

$websites=Invoke-WebRequest -uri "https://localhost:55539/api/webserver/websites" -Credential $u -Headers $x -Method GET -ContentType "application/json"

$websites | ConvertTo-Json