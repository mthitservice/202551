<#

    - Try/Catch /Finally
    - Error Actions
    - $Error Object
#>

function Get-FileContentSafe {
    param([string]$path)
    #E - Variablen Deklaration und Initialisierung der Standartwerte
    #V
        try {
                $content=Get-Content -Path $path -ErrorAction Stop
                return $content
        } catch{
            Write-Warning "Die Datei konnte nicht gelesen werden : $path"
            Write-Warning "Fehler: $($_.Exception.Message)"
            return $null
        }

    #A
}
Get-FileContentSafe -path "c:\Nicht.txt"

# Catch mit Fehlertypen

function Test-ErrorTypes {
    param (

        [Parameter(Mandatory)]
        [ValidateSet('FileNotFound','InvalidOperation','Generic')]
        [string]$ErrorType
     
    )


        try {
            
                switch($ErrorType)
                {
                    'FileNotFound' {
                            Get-Item "c:\datei.txt" -ErrorAction Stop

                    }
                    'InvalidOperation'{ 
                        # Eigenen Fehler auslösen
                        throw [System.InvalidOperationException]::new("Ungültige Operation")

                    }
                    'Generic'{
                        throw "Allgemeiner Fehrer"

                    }

                }
        }
        catch [System.Management.Automation.ItemNotFoundException]
            {
                Write-Host "Catch: Datei oder Pfad nicht gefunden " -ForegroundColor Yellow

            }
       catch [System.InvalidOperationException]
            {
                Write-Host "Catch: Ungültige Operstion " -ForegroundColor Red

            }
        
        catch {
            Write-Host "Catch: Allgemeiner Fehler: $($_.Exception.Message)" -ForegroundColor Magenta
            <#Do this if a terminating exception happens#>
        }
        finally{
            Write-Host " Wird immer ausgeführt" -ForegroundColor Cyan

        }
    
}

Test-ErrorTypes -ErrorType FileNotFound
Test-ErrorTypes -ErrorType InvalidOperation

Test-ErrorTypes -ErrorType Generic
