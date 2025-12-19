# Beispiel SQL Server Verbindung

$server="192.168.102.114"
$database="ITHDB"
$dbuser="sa"
$dbpw="Pa55w0rdPa55w0rd"

# Connection Objekt erzeugen
$cs="Server=$server;Database=$database;User ID=$dbuser;Password=$dbpw;TrustServerCertificate=True"
$cs
$connection=New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString=$cs
$connection.Open()

# Recordset Objekt erzeugen
$query="Select * from tab_data1"
$command=$connection.CreateCommand()
$command.CommandText=$query

$adapter=New-Object System.Data.SqlClient.SqlDataAdapter $command
$dataset=New-Object System.Data.DataSet
# Datenabruf
$adapter.Fill($dataset)

$dataset.Tables[0] | ft

$connection.Close()

# Mit Powershell
#Install-Module SQL
#Import-Module SQL

#Invoke-sqlcmd -SerInstance "192.168.102.114" -Database $database -Username $dbuser -Password $dbpw -Query $query -TrustedConnection
