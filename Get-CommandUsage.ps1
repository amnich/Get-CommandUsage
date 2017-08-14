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
			- if module parameter was provided search for Import-Module
	.PARAMETER Command
		Single command or array of commands.
	.PARAMETER Path
		Path to PS1 files.
		Default current directory.
	.PARAMETER Recurse
		Recurse switch for Path parameter.
	.PARAMETER Module
		Module to load all commands from.
	.EXAMPLE
		Get-CommandUsage -Command Get-ChildItem -Path C:\Scripts -Recurse

		Find usage of Get-ChildItem in all PS1 scripts in C:\Scripts and subdirectories
	.EXAMPLE
		Get-CommandUsage -Module SomeModule

		Find all used commands from module SomeModule in scripts in current directory

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
	[ValidateNotNullorEmpty()]
	[string]$Module

)
	BEGIN{
		function Find-CommandInAst {
		    param([System.Management.Automation.Language.Ast] $Ast)
		    end {
		        return $Ast -is [System.Management.Automation.Language.CommandAst] -and
		               $Ast.GetCommandName() -eq $command
		    }
		}

		if ($PSCmdlet.MyInvocation.BoundParameters["Module"] -ne $null){
			Write-Verbose "Get $Module commands"
			$commands = (Get-Command -Module $Module).Name
			Write-Verbose "Got $($commands.count) commands"
			Write-Debug "$($commands | out-string)"
			if ($commands -eq $null){
				Write-Error "No commands from module $module"
				break
			}
		}
		else{
			$commands = $command
		}
		$pathParams = @{
			Filter = "*.ps1"
		}
		if ($PSCmdlet.MyInvocation.BoundParameters["Recurse"].IsPresent){
			$pathParams += @{
				Recurse = $true
			}
		}

		Write-Verbose "Get files from repository"
		$files = Get-ChildItem $Path @pathParams
		Write-Verbose "Got $($files.Count) files"
		$regexModule = "(?i)^\s{0,}(#{0,})\s*Import-Module.+$module"
	} #BEGIN end
	PROCESS{
		foreach ($file in $files){
			$results = @()
			Write-Verbose "   $($file.fullname)"
			$scriptFileAst = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
			Foreach ($command in $commands){
				Write-Debug "      Find $command using regex"
				if ($scriptFileAst.Extent.Text | Select-String -Pattern "(?i)$command") {
					Write-Debug "		Get command usage with Ast"
					$results += $scriptFileAst.FindAll(${function:Find-CommandInAst}, $true)
				}
			}
			If ($results){
				Write-Verbose "      Command usage found."
				if ($PSCmdlet.MyInvocation.BoundParameters["Module"] -ne $null){
					Write-Verbose "      Module import $Module check"
					$ModuleImport = Select-String -Pattern $regexModule -Path $file.FullName
				}
				foreach ($res in $results){
					Write-Verbose "     $($res.extent.text)"
						$obj = New-Object PSCustomObject -Property ([ordered]@{
						Command = $res.CommandElements[0].value
						Script = $file.name
						Path = $file.FullName
						CommandLine = $res.Parent
						LineNumber = $res.extent.StartLineNumber
						ModuleImport = $(if($ModuleImport){$true}else{$false})
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
