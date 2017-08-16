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

#### Find usage of Get-ChildItem in all PS1 scripts in C:\Scripts and subdirectories
```powershell
		PS > Get-CommandUsage -Command Get-ChildItem -Path C:\Scripts -Recurse
		
		Command      : Get-ChildItem
		Script       : copy-items.ps1
		Path         : C:\Scripts\copy-items.ps1
		CommandLine  : Get-ChildItem $path_out -Filter *.pdf -ErrorVariable +my_error
		LineNumber   : 40
```
#### Find usage of Get-ChildItem and its aliases in C:\Scripts\copy-items.ps1 script. 
#### Expands alias in returned results in Command property
```powershell
		PS > Get-CommandUsage -Command Get-ChildItem -AliasExpand -Path C:\Scripts\copy-items.ps1 
		
		Command      : Get-ChildItem
		Script       : copy-items.ps1
		Path         : C:\Scripts\copy-items.ps1
		CommandLine  : Get-ChildItem $path_out -Filter *.pdf -ErrorVariable +my_error
		LineNumber   : 40
		
		Command      : Get-ChildItem
		Script       : copy-items.ps1
		Path         : C:\Scripts\copy-items.ps1
		CommandLine  : gci $path_in 
		LineNumber   : 41	
```
#### Find all used commands from module SomeModule in scripts in current directory
```powershell
		PS > Get-CommandUsage -Module SomeModule
		
		Command      : Get-SQLDataTable
		Script       : get-ServerInfo.ps1
		Path         : C:\Scripts\get-ServerInfo.ps1
		CommandLine  : Get-SQLDataTable -Query "SELECT ComputerName, Max(TimeCreated) as MaxDate from ServerLogs group by ComputerName"
		LineNumber   : 50		
```
#### Find all commands in scripts in C:\Scripts
```powershell

		PS > Get-CommandUsage -All -Path C:\Scripts
		
		Command      : Get-ChildItem
		Script       : copy-items.ps1
		Path         : C:\Scripts\copy-items.ps1
		CommandLine  : Get-ChildItem $path_in 
		LineNumber   : 4		
```
