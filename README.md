# Get-CommandUsage

Find command usage in script files using the System.Management.Automation.Language.Ast.

Get all PS1 files from Path and search for a single command, array of commands, all commands from a module or all commands used.

Function returs and object with information about

* command name
* script name
* script path
* command line in script
* line number of command		

## Example

```powershell
PS > Get-CommandUsage -Command Get-ChildItem -Path C:\Scripts

Command      : Get-ChildItem
Script       : copy-items.ps1
Path         : C:\Scripts\copy-items.ps1
CommandLine  : Get-ChildItem $path_out -Filter *.pdf -ErrorVariable +my_error
LineNumber   : 40
```

```powershell
PS > Get-CommandUsage -Module MyModule -Path C:\Scripts -Recurse

Command      : Get-SQLDataTable
Script       : get-ServerInfo.ps1
Path         : C:\Scripts\get-ServerInfo.ps1
CommandLine  : Get-SQLDataTable -Query "SELECT ComputerName, Max(TimeCreated) as MaxDate from ServerLogs group by ComputerName"
LineNumber   : 50

```

```powershell
PS > Get-CommandUsage -All -Path C:\Scripts

Command      : Get-ChildItem
Script       : copy-items.ps1
Path         : C:\Scripts\copy-items.ps1
CommandLine  : Get-ChildItem $path_in 
LineNumber   : 4
```
