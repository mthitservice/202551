function Invoke-RunspacePool {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Object[]]
        $InputObjects,

        [Parameter(Mandatory)]
        [scriptblock]
        $ScriptBlock,
        # Maximal gleichzeitige Threads
        [int]$ThrottleLimit = [Environment]::ProcessorCount,

        [switch]$WriteVerboseErrors # Optional Fehler aus Streams anzeigen
    )

    # Runspace Pool
    $rsp = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $rsp, $Host)

    $pool.Open()
    $jobs = New-Object System.Collections.Generic.List[object]


        foreach ($obj in $InputObjects) {
            # Powershell Instanz erstellen
            $ps = [powershell]::Create()
            # Instanz dem Runspace Prezoss Zuweisen
            $ps.RunspacePool = $pool
            # Powershell Script hinzufügen
            $null = $ps.AddScript($ScriptBlock).AddArgument($obj)
            #Asynchron starten
            $handle = $ps.BeginInvoke()
            # In Jobwarteschlange merken
            $jobs.Add([PSCustomObject]@{
                    PS     = $ps
                    Handle = $handle
                })

        }

        
        try {
          
            foreach ($i in $jobs) {
                try {
                    $output = $i.PS.EndInvoke($i.Handle)
                    # Write Verbose Fehler anzeigen
                    $output  
                    
                }
                finally {
                    $i.Ps.Dispose()

                } 
            }
                                        
        }
        finally {
            $pool.Close()
            $pool.Dispose()

        }
    }



        


    $files = Get-ChildItem "C:\Windows\System32" -File -ErrorAction SilentlyContinue | Select-Object -First 50

    $results = Invoke-RunspacePool -InputObjects $files -ThrottleLimit 4 -ScriptBlock {

        param($file)
        $hash = Get-FileHash -Path $file.Fullname -Algorithm SHA256

        [PSCustomObject]@{
            Name      = $file.Name
            Path      = $file.Fullname
            Hash      = $hash.Hash
            ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            TimeStamp = Get-Date
        } 

    }-WriteVerboseErrors

    $results | Format-Table