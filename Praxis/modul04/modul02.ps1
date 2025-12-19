# Klassen Formatdatei
# Generieren

$formatXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <ViewDefinitions>
        <!-- Table View für ServerHealthReport -->
        <View>
            <Name>ServerHealthReport.TableView</Name>
            <ViewSelectedBy>
                <TypeName>ServerHealthReport</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
                    <TableColumnHeader>
                        <Label>Computer</Label>
                        <Width>20</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Status</Label>
                        <Width>10</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Uptime</Label>
                        <Width>12</Width>
                        <Alignment>Right</Alignment>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Memory%</Label>
                        <Width>10</Width>
                        <Alignment>Right</Alignment>
                    </TableColumnHeader>
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>
                            <TableColumnItem>
                                <PropertyName>ComputerName</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Status</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>"{0:N1} days" -f $_.UptimeDays</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <ScriptBlock>"{0:N1}%" -f $_.MemoryUsedPercent</ScriptBlock>
                            </TableColumnItem>
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
        
        <!-- List View für ServerHealthReport -->
        <View>
            <Name>ServerHealthReport.ListView</Name>
            <ViewSelectedBy>
                <TypeName>ServerHealthReport</TypeName>
            </ViewSelectedBy>
            <ListControl>
                <ListEntries>
                    <ListEntry>
                        <ListItems>
                            <ListItem>
                                <Label>Server</Label>
                                <PropertyName>ComputerName</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>Health Status</Label>
                                <PropertyName>Status</PropertyName>
                            </ListItem>
                            <ListItem>
                                <Label>System Uptime</Label>
                                <ScriptBlock>"{0:N2} days ({1:N0} hours)" -f $_.UptimeDays, ($_.UptimeDays * 24)</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Memory Usage</Label>
                                <ScriptBlock>"{0:N1}% used" -f $_.MemoryUsedPercent</ScriptBlock>
                            </ListItem>
                            <ListItem>
                                <Label>Last Checked</Label>
                                <ScriptBlock>$_.LastCheck.ToString("yyyy-MM-dd HH:mm:ss")</ScriptBlock>
                            </ListItem>
                        </ListItems>
                    </ListEntry>
                </ListEntries>
            </ListControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@

$FormatPath= Join-Path $env:TEMP "ServerHealthReport.Format.ps1xml"
$formatXml | Out-File $FormatPath  -Encoding utf8
$env:TEMP