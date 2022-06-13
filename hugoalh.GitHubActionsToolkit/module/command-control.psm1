#Requires -PSEdition Core
#Requires -Version 7.2
Import-Module -Name @(
	(Join-Path -Path $PSScriptRoot -ChildPath 'command-base.psm1')
) -Prefix 'GitHubActions' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Disable Echoing Commands
.DESCRIPTION
Disable echoing of commands, the run's log will not show the command itself; A command is echoed if there are any errors processing the command; Secret `ACTIONS_STEP_DEBUG` will ignore this.
.OUTPUTS
Void
#>
function Disable-EchoingCommands {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_disable-githubactionsechoingcommands#Disable-GitHubActionsEchoingCommands')]
	[OutputType([void])]
	param ()
	return Write-GitHubActionsCommand -Command 'echo' -Message 'off'
}
Set-Alias -Name 'Disable-CommandEcho' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-CommandEchoing' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-CommandsEcho' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-CommandsEchoing' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-EchoCommand' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-EchoCommands' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-EchoingCommand' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandEcho' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandEchoing' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandsEcho' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandsEchoing' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-EchoCommand' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-EchoCommands' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-EchoingCommand' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-EchoingCommands' -Value 'Disable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Disable Processing Commands
.DESCRIPTION
Stop processing any commands to allow log anything without accidentally running commands.
.PARAMETER EndToken
An end token for function `Enable-GitHubActionsProcessingCommands`.
.OUTPUTS
String
#>
function Disable-ProcessingCommands {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_disable-githubactionsprocessingcommands#Disable-GitHubActionsProcessingCommands')]
	[OutputType([string])]
	param (
		[Parameter(Position = 0)][ValidateScript({
			return ($_ -match '^.+$' -and $_.Length -ge 4 -and $_ -inotin @(
				'add-mask',
				'add-matcher',
				'debug',
				'echo',
				'endgroup',
				'error',
				'group',
				'notice',
				'remove-matcher',
				'save-state',
				'set-output',
				'warning'
			))
		}, ErrorMessage = 'Parameter `EndToken` must be in single line string, more than or equal to 4 characters, not match any GitHub Actions commands, and unique!')][Alias('EndKey', 'EndValue', 'Key', 'Token', 'Value')][string]$EndToken = ((New-Guid).Guid -replace '-', '')
	)
	Write-GitHubActionsCommand -Command 'stop-commands' -Message $EndToken
	return $EndToken
}
Set-Alias -Name 'Disable-CommandProcess' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-CommandProcessing' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-CommandsProcess' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-CommandsProcessing' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-ProcessCommand' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-ProcessCommands' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-ProcessingCommand' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandProcess' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandProcessing' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandsProcess' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-CommandsProcessing' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-ProcessCommand' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-ProcessCommands' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-ProcessingCommand' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Stop-ProcessingCommands' -Value 'Disable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Enable Echoing Commands
.DESCRIPTION
Enable echoing of commands, the run's log will show the command itself; Commands `add-mask`, `debug`, `warning`, and `error` do not support echoing because their outputs are already echoed to the log; Secret `ACTIONS_STEP_DEBUG` will ignore this.
.OUTPUTS
Void
#>
function Enable-EchoingCommands {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_enable-githubactionsechoingcommands#Enable-GitHubActionsEchoingCommands')]
	[OutputType([void])]
	param ()
	return Write-GitHubActionsCommand -Command 'echo' -Message 'on'
}
Set-Alias -Name 'Enable-CommandEcho' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-CommandEchoing' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-CommandsEcho' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-CommandsEchoing' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-EchoCommand' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-EchoCommands' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-EchoingCommand' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandEcho' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandEchoing' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandsEcho' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandsEchoing' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-EchoCommand' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-EchoCommands' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-EchoingCommand' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-EchoingCommands' -Value 'Enable-EchoingCommands' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Enable Processing Commands
.DESCRIPTION
Resume processing any commands to allow running commands.
.PARAMETER EndToken
An end token from function `Disable-GitHubActionsProcessingCommands`.
.OUTPUTS
Void
#>
function Enable-ProcessingCommands {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_enable-githubactionsprocessingcommands#Enable-GitHubActionsProcessingCommands')]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][ValidateScript({
			return ($_ -match '^.+$' -and $_.Length -ge 4 -and $_ -inotin @(
				'add-mask',
				'add-matcher',
				'debug',
				'echo',
				'endgroup',
				'error',
				'group',
				'notice',
				'remove-matcher',
				'save-state',
				'set-output',
				'warning'
			))
		}, ErrorMessage = 'Parameter `EndToken` must be in single line string, more than or equal to 4 characters, and not match any GitHub Actions commands!')][Alias('EndKey', 'EndValue', 'Key', 'Token', 'Value')][string]$EndToken
	)
	return Write-GitHubActionsCommand -Command $EndToken
}
Set-Alias -Name 'Enable-CommandProcess' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-CommandProcessing' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-CommandsProcess' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-CommandsProcessing' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-ProcessCommand' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-ProcessCommands' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-ProcessingCommand' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandProcess' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandProcessing' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandsProcess' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-CommandsProcessing' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-ProcessCommand' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-ProcessCommands' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-ProcessingCommand' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Start-ProcessingCommands' -Value 'Enable-ProcessingCommands' -Option 'ReadOnly' -Scope 'Local'
Export-ModuleMember -Function @(
	'Disable-EchoingCommands',
	'Disable-ProcessingCommands',
	'Enable-EchoingCommands',
	'Enable-ProcessingCommands'
) -Alias @(
	'Disable-CommandEcho',
	'Disable-CommandEchoing',
	'Disable-CommandProcess',
	'Disable-CommandProcessing',
	'Disable-CommandsEcho',
	'Disable-CommandsEchoing',
	'Disable-CommandsProcess',
	'Disable-CommandsProcessing',
	'Disable-EchoCommand',
	'Disable-EchoCommands',
	'Disable-EchoingCommand',
	'Disable-ProcessCommand',
	'Disable-ProcessCommands',
	'Disable-ProcessingCommand',
	'Enable-CommandEcho',
	'Enable-CommandEchoing',
	'Enable-CommandProcess',
	'Enable-CommandProcessing',
	'Enable-CommandsEcho',
	'Enable-CommandsEchoing',
	'Enable-CommandsProcess',
	'Enable-CommandsProcessing',
	'Enable-EchoCommand',
	'Enable-EchoCommands',
	'Enable-EchoingCommand',
	'Enable-ProcessCommand',
	'Enable-ProcessCommands',
	'Enable-ProcessingCommand',
	'Start-CommandEcho',
	'Start-CommandEchoing',
	'Start-CommandProcess',
	'Start-CommandProcessing',
	'Start-CommandsEcho',
	'Start-CommandsEchoing',
	'Start-CommandsProcess',
	'Start-CommandsProcessing',
	'Start-EchoCommand',
	'Start-EchoCommands',
	'Start-EchoingCommand',
	'Start-EchoingCommands',
	'Start-ProcessCommand',
	'Start-ProcessCommands',
	'Start-ProcessingCommand',
	'Start-ProcessingCommands',
	'Stop-CommandEcho',
	'Stop-CommandEchoing',
	'Stop-CommandProcess',
	'Stop-CommandProcessing',
	'Stop-CommandsEcho',
	'Stop-CommandsEchoing',
	'Stop-CommandsProcess',
	'Stop-CommandsProcessing',
	'Stop-EchoCommand',
	'Stop-EchoCommands',
	'Stop-EchoingCommand',
	'Stop-EchoingCommands',
	'Stop-ProcessCommand',
	'Stop-ProcessCommands',
	'Stop-ProcessingCommand',
	'Stop-ProcessingCommands'
)