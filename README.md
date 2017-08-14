# Get-CommandUsage

```powershell
PS > Get-CommandUsage -Command Get-ChildItem -Path C:\Scripts

Command      : Get-ChildItem
Script       : copy-items.ps1
Path         : C:\Scripts\copy-items.ps1
CommandLine  : Get-ChildItem $path_out -Filter *.pdf -ErrorVariable +my_error
LineNumber   : 40
ModuleImport : False
```

```powershell
PS > Get-CommandUsage -Module MyModule -Path C:\Scripts -Recurse

Command      : Get-SQLDataTable
Script       : get-ServerInfo.ps1
Path         : C:\Scripts\get-ServerInfo.ps1
CommandLine  : Get-SQLDataTable -Query "SELECT ComputerName, Max(TimeCreated) as MaxDate from ServerLogs group by ComputerName"
LineNumber   : 50
ModuleImport : True

```
