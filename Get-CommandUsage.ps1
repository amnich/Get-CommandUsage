function Get-CommandUsage {
<#
	.SYNOPSIS
		Find command usage in script files.
	.DESCRIPTION
		Find command usage in script files using the System.Management.Automation.Language.Ast.
		Get all PS1 files from Path and search for a single command, array of commands or all commands from a module.
		Function returs and object with information about
			- command name
			- script name
			- script path
			- command line in script
			- line number of command			
	.PARAMETER Command
		Single command or array of commands.
	.PARAMETER Path
		Path to PS1 files.
		Default current directory.
	.PARAMETER Recurse
		Recurse switch for Path parameter.
	.PARAMETER Module
		Module to load all commands from.		
	.PARAMETER All
		Get all commands from script.
	.PARAMETER AliasExpand
		Find all aliases for a command and search also for them in a script file.
		It expands also the alias in the returned results.
	.EXAMPLE
		Get-CommandUsage -Command Get-ChildItem -Path C:\Scripts -Recurse
		
		Command      : Get-ChildItem
		Script       : copy-items.ps1
		Path         : C:\Scripts\copy-items.ps1
		CommandLine  : Get-ChildItem $path_out -Filter *.pdf -ErrorVariable +my_error
		LineNumber   : 40

		Find usage of Get-ChildItem in all PS1 scripts in C:\Scripts and subdirectories
	
	.EXAMPLE
		Get-CommandUsage -Command Get-ChildItem -AliasExpand -Path C:\Scripts\copy-items.ps1 
		
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

		Find usage of Get-ChildItem and its aliases in C:\Scripts\copy-items.ps1 script. 
		Expands alias in returned results in Command property
	
	.EXAMPLE
		Get-CommandUsage -Module SomeModule
		
		Command      : Get-SQLDataTable
		Script       : get-ServerInfo.ps1
		Path         : C:\Scripts\get-ServerInfo.ps1
		CommandLine  : Get-SQLDataTable -Query "SELECT ComputerName, Max(TimeCreated) as MaxDate from ServerLogs group by ComputerName"
		LineNumber   : 50

		Find all used commands from module SomeModule in scripts in current directory
		
	.EXAMPLE
		Get-CommandUsage -All -Path C:\Scripts
		
		Command      : Get-ChildItem
		Script       : copy-items.ps1
		Path         : C:\Scripts\copy-items.ps1
		CommandLine  : Get-ChildItem $path_in 
		LineNumber   : 4
		
		Find all commands in scripts in C:\Scripts

	.NOTES
		Thanks to Seemingly Science (https://seeminglyscience.github.io/) for giving me the language parser solution.
	.LINK
		https://github.com/amnich/Get-CommandUsage
#>
[cmdletbinding()]
param(
[parameter(ParameterSetName='Command',Mandatory=$True)]
	[ValidateNotNullorEmpty()]
	[string[]]$Command,
	[ValidateScript({Test-Path $_ })]
	[string]$Path = $PWD.Path,
	[switch]$Recurse,
	[parameter(ParameterSetName='Module',Mandatory=$True)]
	[ValidateScript({Get-Module -ListAvailable -Name $_ })]
	[string]$Module,
	[parameter(ParameterSetName='All',Mandatory=$True)]
	[switch]$All,
	[switch]$AliasExpand

)
	BEGIN{
		function Find-CommandInAst {
		    param([System.Management.Automation.Language.Ast] $Ast)
		    end {
		        return $Ast -is [System.Management.Automation.Language.CommandAst] -and
		               $Ast.GetCommandName() -eq $commandToFind
		    }
		}

		if ($PSCmdlet.MyInvocation.BoundParameters["Module"] -ne $null){
			Write-Verbose "Get $Module commands."
			$commands = (Get-Command -Module $Module).Name
			if ($commands -eq $null){
				Write-Error "No commands from module $module`n$($Error[0] | out-string)"
				break
			}
			Write-Verbose "Got $($commands.count) commands."
			Write-Debug "$($commands | out-string)"			
		}
		else{
			$commands = $command
		}
		$pathParams = @{
			Path = $Path
			Filter = "*.ps1"
		}
		if ($PSCmdlet.MyInvocation.BoundParameters["Recurse"].IsPresent){
			$pathParams += @{
				Recurse = $true
			}
		}
		Write-Verbose "Get files from directory."
		$files = Get-ChildItem @pathParams
		Write-Verbose "Got $($files.Count) files."		
	} #BEGIN end
	PROCESS{
		foreach ($file in $files){
			#create new generic list to store results
			$results = New-Object System.Collections.Generic.List[System.Management.Automation.Language.Ast]]
			Write-Verbose "   $($file.fullname)"
			#parse script file using ParseFile method
			$scriptFileAst = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
			#Get specific commands from script file 
			If (!$PSCmdlet.MyInvocation.BoundParameters["All"].IsPresent){					
				Foreach ($command in $commands){					
					Write-Debug "      Find $command using regex"
					if ($scriptFileAst.Extent.Text | Select-String -Pattern "(?i)$command") {
						Write-Debug "		Get command usage with Ast"
						$commandToFind = $command
						$results.AddRange($scriptFileAst.FindAll(${function:Find-CommandInAst}, $true))
					}
					#expand command aliases and find them in script
					If ($PSCmdlet.MyInvocation.BoundParameters["AliasExpand"].IsPresent){
						Write-Debug "      Expand command aliases"
						$aliases = Get-Alias -Definition $command -ErrorAction SilentlyContinue | select -ExpandProperty Name
						foreach ($alias in $aliases){
							Write-Debug "       Find $alias using regex"
							if ($scriptFileAst.Extent.Text | Select-String -Pattern "(?i)$alias") {
								Write-Debug "		Get command usage with Ast"
								$commandToFind = $alias
								$results.AddRange($scriptFileAst.FindAll(${function:Find-CommandInAst}, $true))
							}
						}
					}
				}
			}
			#Get all commands from script file
			else{
				$results.AddRange($scriptFileAst.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true))
			}
			#if something found create object foreach result to return
			If ($results){
				Write-Verbose "      Command usage found."				
				foreach ($res in $results){
					Write-Verbose "     $($res.extent.text)"
						$obj = New-Object PSCustomObject -Property ([ordered]@{
						Command = $(if ($AliasExpand){
									try {
										Get-Alias $res.CommandElements[0].value -ErrorAction Stop | Select -ExpandProperty Definition
									}
									catch{
										$res.CommandElements[0].value
									}
								}
								else{$res.CommandElements[0].value})
						Script = $file.name
						Path = $file.FullName
						CommandLine = $res.Parent
						LineNumber = $res.extent.StartLineNumber						
					})
					Write-Debug "$($obj | out-string)"
					$obj
				}
			}
			else{
				Write-Debug "      No command usage found"
			}
		}
	}	#PROCESS END
} #function end
