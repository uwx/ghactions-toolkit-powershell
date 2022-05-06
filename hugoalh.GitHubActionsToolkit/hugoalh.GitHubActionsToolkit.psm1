#Requires -PSEdition Core
#Requires -Version 7.2
enum GitHubActionsAnnotationType {
	Notice = 0
	N = 0
	Note = 0
	Warning = 1
	W = 1
	Warn = 1
	Error = 2
	E = 2
}
<#
.SYNOPSIS
GitHub Actions - Internal - Format Command
.DESCRIPTION
An internal function to escape command characters that could cause issues.
.PARAMETER InputObject
String that need to escape command characters.
.PARAMETER Property
Also escape command property characters.
.OUTPUTS
String
#>
function Format-GitHubActionsCommand {
	[CmdletBinding()][OutputType([string])]
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][AllowEmptyString()][Alias('Input', 'Object')][string]$InputObject,
		[switch]$Property
	)
	begin {}
	process {
		[string]$Result = $InputObject -replace '%', '%25' -replace "\n", '%0A' -replace "\r", '%0D'
		if ($Property) {
			$Result = $Result -replace ',', '%2C' -replace ':', '%3A'
		}
		return $Result
	}
	end {}
}
Set-Alias -Name 'Format-GHActionsCommand' -Value 'Format-GitHubActionsCommand' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Internal - Write Workflow Command
.DESCRIPTION
An internal function to write workflow command.
.PARAMETER Command
Workflow command.
.PARAMETER Message
Message.
.PARAMETER Property
Workflow command property.
.OUTPUTS
Void
#>
function Write-GitHubActionsCommand {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^.+$')][string]$Command,
		[Parameter(Position = 1)][AllowEmptyString()][Alias('Content', 'SubCommand')][string]$Message = '',
		[Parameter(Position = 2)][Alias('Properties')][hashtable]$Property = @{}
	)
	[string]$Result = "::$Command"
	if ($Property.Count -gt 0) {
		$Result += " $(($Property.GetEnumerator() | ForEach-Object -Process {
			return "$($_.Name)=$(Format-GitHubActionsCommand -InputObject $_.Value -Property)"
		}) -join ',')"
	}
	$Result += "::$(Format-GitHubActionsCommand -InputObject $Message)"
	Write-Host -Object $Result
}
Set-Alias -Name 'Write-GHActionsCommand' -Value 'Write-GitHubActionsCommand' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Add Environment Variable
.DESCRIPTION
Add environment variable to the system environment variables and automatically makes it available to all subsequent actions in the current job; The currently running action cannot access the updated environment variables.
.PARAMETER InputObject
Environment variable.
.PARAMETER Name
Environment variable name.
.PARAMETER Value
Environment variable value.
.OUTPUTS
Void
#>
function Add-GitHubActionsEnvironmentVariable {
	[CmdletBinding(DefaultParameterSetName = 'multiple')][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'multiple', Position = 0, ValueFromPipeline = $true)][Alias('Input', 'Object')][hashtable]$InputObject,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 0)][ValidatePattern('^(?:[\da-z][\da-z_]*)?[\da-z]$')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 1)][ValidatePattern('^.+$')][string]$Value
	)
	begin {
		[hashtable]$Result = @{}
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'multiple' {
				$InputObject.GetEnumerator() | ForEach-Object -Process {
					if ($_.Name.GetType().Name -ne 'string') {
						Write-Error -Message "Environment variable name `"$($_.Name)`" must be type of string!" -Category 'InvalidType'
					} elseif ($_.Name -notmatch '^(?:[\da-z][\da-z_]*)?[\da-z]$') {
						Write-Error -Message "Environment variable name `"$($_.Name)`" is not match the require pattern!" -Category 'SyntaxError'
					} elseif ($_.Value.GetType().Name -ne 'string') {
						Write-Error -Message "Environment variable value `"$($_.Value)`" must be type of string!" -Category 'InvalidType'
					} elseif ($_.Value -notmatch '^.+$') {
						Write-Error -Message "Environment variable value `"$($_.Value)`" is not match the require pattern!" -Category 'SyntaxError'
					} else {
						$Result[$_.Name] = $_.Value
					}
				}
				break
			}
			'single' {
				$Result[$Name] = $Value
				break
			}
		}
	}
	end {
		Add-Content -Path $env:GITHUB_ENV -Value "$(($Result.GetEnumerator() | ForEach-Object -Process {
			return "$($_.Name)=$($_.Value)"
		}) -join "`n")" -Encoding 'UTF8NoBOM'
	}
}
Set-Alias -Name 'Add-GHActionsEnv' -Value 'Add-GitHubActionsEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GHActionsEnvironment' -Value 'Add-GitHubActionsEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GHActionsEnvironmentVariable' -Value 'Add-GitHubActionsEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GitHubActionsEnv' -Value 'Add-GitHubActionsEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GitHubActionsEnvironment' -Value 'Add-GitHubActionsEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Add PATH
.DESCRIPTION
Add directory to the system `PATH` variable and automatically makes it available to all subsequent actions in the current job; The currently running action cannot access the updated path variable.
.PARAMETER Path
System path.
.OUTPUTS
Void
#>
function Add-GitHubActionsPATH {
	[CmdletBinding()][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^.+$')][Alias('Paths')][string[]]$Path
	)
	begin {
		[string[]]$Result = @()
	}
	process {
		$Path | ForEach-Object -Process {
			if (Test-Path -Path $_ -IsValid) {
				$Result += $_
			} else {
				Write-Error -Message "Path `"$_`" is not match the require path pattern!" -Category 'SyntaxError'
			}
		}
	}
	end {
		Add-Content -Path $env:GITHUB_PATH -Value "$($Result -join "`n")" -Encoding 'UTF8NoBOM'
	}
}
Set-Alias -Name 'Add-GHActionsPATH' -Value 'Add-GitHubActionsPATH' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Add Problem Matcher
.DESCRIPTION
Problem matchers are a way to scan the output of actions for a specified regular expression pattern and automatically surface that information prominently in the user interface, both annotations and log file decorations are created when a match is detected. For more information, please visit https://github.com/actions/toolkit/blob/main/docs/problem-matchers.md.
.PARAMETER Path
Relative path to the JSON file problem matcher.
.OUTPUTS
Void
#>
function Add-GitHubActionsProblemMatcher {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][SupportsWildcards()][ValidatePattern('^.+$')][Alias('File', 'Files', 'Paths', 'PSPath', 'PSPaths')][string[]]$Path
	)
	begin {}
	process {
		$Path | ForEach-Object -Process {
			[string[]](Resolve-Path -Path $_ -Relative) | ForEach-Object -Process {
				Write-GitHubActionsCommand -Command 'add-matcher' -Message ($_ -replace '^\.[\\\/]', '' -replace '\\', '/')
			}
		}
	}
	end {}
}
Set-Alias -Name 'Add-GHActionsProblemMatcher' -Value 'Add-GitHubActionsProblemMatcher' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Add Secret Mask
.DESCRIPTION
Make a secret will get masked from the log.
.PARAMETER Value
The secret.
.PARAMETER Smart
Use improved method to well make a secret will get masked from the log.
.OUTPUTS
Void
#>
function Add-GitHubActionsSecretMask {
	[CmdletBinding()][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][Alias('Key', 'Token')][string]$Value,
		[switch]$Smart
	)
	begin {}
	process {
		Write-GitHubActionsCommand -Command 'add-mask' -Message $Value
		if ($Smart) {
			[string[]]($Value -split '[\n\r\s\t]+') | ForEach-Object -Process {
				if (($_ -ne $Value) -and ($_.Length -ge 2)) {
					Write-GitHubActionsCommand -Command 'add-mask' -Message $_
				}
			}
		}
	}
	end {}
}
Set-Alias -Name 'Add-GHActionsMask' -Value 'Add-GitHubActionsSecretMask' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GHActionsSecret' -Value 'Add-GitHubActionsSecretMask' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GitHubActionsMask' -Value 'Add-GitHubActionsSecretMask' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GitHubActionsSecret' -Value 'Add-GitHubActionsSecretMask' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Disable Echo Command
.DESCRIPTION
Disable echoing of workflow commands, the workflow run's log will not show the command itself; A workflow command is echoed if there are any errors processing the command; Secret `ACTIONS_STEP_DEBUG` will ignore this.
.OUTPUTS
Void
#>
function Disable-GitHubActionsEchoCommand {
	[CmdletBinding()][OutputType([void])]
	param()
	Write-GitHubActionsCommand -Command 'echo' -Message 'off'
}
Set-Alias -Name 'Disable-GHActionsCommandEcho' -Value 'Disable-GitHubActionsEchoCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-GHActionsEchoCommand' -Value 'Disable-GitHubActionsEchoCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-GitHubActionsCommandEcho' -Value 'Disable-GitHubActionsEchoCommand' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Disable Processing Command
.DESCRIPTION
Stop processing any workflow commands to allow log anything without accidentally running workflow commands.
.PARAMETER EndToken
An end token for function `Enable-GitHubActionsProcessingCommand`.
.OUTPUTS
String
#>
function Disable-GitHubActionsProcessingCommand {
	[CmdletBinding()][OutputType([string])]
	param(
		[Parameter(Position = 0)][ValidatePattern('^.+$')][Alias('EndKey', 'EndValue', 'Key', 'Token', 'Value')][string]$EndToken = (New-Guid).Guid
	)
	Write-GitHubActionsCommand -Command 'stop-commands' -Message $EndToken
	return $EndToken
}
Set-Alias -Name 'Disable-GHActionsCommandProcessing' -Value 'Disable-GitHubActionsProcessingCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-GHActionsProcessingCommand' -Value 'Disable-GitHubActionsProcessingCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Disable-GitHubActionsCommandProcessing' -Value 'Disable-GitHubActionsProcessingCommand' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Enable Echo Command
.DESCRIPTION
Enable echoing of workflow commands, the workflow run's log will show the command itself; The `add-mask`, `debug`, `warning`, and `error` commands do not support echoing because their outputs are already echoed to the log; Secret `ACTIONS_STEP_DEBUG` will ignore this.
.OUTPUTS
Void
#>
function Enable-GitHubActionsEchoCommand {
	[CmdletBinding()][OutputType([void])]
	param()
	Write-GitHubActionsCommand -Command 'echo' -Message 'on'
}
Set-Alias -Name 'Enable-GHActionsCommandEcho' -Value 'Enable-GitHubActionsEchoCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-GHActionsEchoCommand' -Value 'Enable-GitHubActionsEchoCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-GitHubActionsCommandEcho' -Value 'Enable-GitHubActionsEchoCommand' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Enable Processing Command
.DESCRIPTION
Resume processing any workflow commands to allow running workflow commands.
.PARAMETER EndToken
An end token from function `Disable-GitHubActionsProcessingCommand`.
.OUTPUTS
Void
#>
function Enable-GitHubActionsProcessingCommand {
	[CmdletBinding()][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^.+$')][Alias('EndKey', 'EndValue', 'Key', 'Token', 'Value')][string]$EndToken
	)
	Write-GitHubActionsCommand -Command $EndToken -Message ''
}
Set-Alias -Name 'Enable-GHActionsCommandProcessing' -Value 'Enable-GitHubActionsProcessingCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-GHActionsProcessingCommand' -Value 'Enable-GitHubActionsProcessingCommand' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enable-GitHubActionsCommandProcessing' -Value 'Enable-GitHubActionsProcessingCommand' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Enter Log Group
.DESCRIPTION
Create an expandable group in the log; Anything write to the log between `Enter-GitHubActionsLogGroup` and `Exit-GitHubActionsLogGroup` commands are inside an expandable group in the log.
.PARAMETER Title
Title of the log group.
.OUTPUTS
Void
#>
function Enter-GitHubActionsLogGroup {
	[CmdletBinding()][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^.+$')][Alias('Header', 'Message')][string]$Title
	)
	Write-GitHubActionsCommand -Command 'group' -Message $Title
}
Set-Alias -Name 'Enter-GHActionsGroup' -Value 'Enter-GitHubActionsLogGroup' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enter-GHActionsLogGroup' -Value 'Enter-GitHubActionsLogGroup' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Enter-GitHubActionsGroup' -Value 'Enter-GitHubActionsLogGroup' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Exit Log Group
.DESCRIPTION
End an expandable group in the log.
.OUTPUTS
Void
#>
function Exit-GitHubActionsLogGroup {
	[CmdletBinding()][OutputType([void])]
	param ()
	Write-GitHubActionsCommand -Command 'endgroup' -Message ''
}
Set-Alias -Name 'Exit-GHActionsGroup' -Value 'Exit-GitHubActionsLogGroup' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Exit-GHActionsLogGroup' -Value 'Exit-GitHubActionsLogGroup' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Exit-GitHubActionsGroup' -Value 'Exit-GitHubActionsLogGroup' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Get Input
.DESCRIPTION
Get input.
.PARAMETER Name
Name of the input.
.PARAMETER Require
Whether the input is require. If required and not present, will throw an error.
.PARAMETER All
Get all of the input.
.PARAMETER Trim
Trim the input's value.
.OUTPUTS
Hashtable | String
#>
function Get-GitHubActionsInput {
	[CmdletBinding(DefaultParameterSetName = 'select')][OutputType([hashtable], [string])]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'select', Position = 0, ValueFromPipeline = $true)][SupportsWildcards()][ValidatePattern('^.+$')][Alias('Key', 'Keys', 'Names')][string[]]$Name,
		[Parameter(ParameterSetName = 'select')][Alias('Required')][switch]$Require,
		[Parameter(ParameterSetName = 'all')][switch]$All,
		[switch]$Trim
	)
	begin {
		[hashtable]$Result = @{}
		[bool]$ResultIsHashtable = $false
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'all' {
				$ResultIsHashtable = $true
				Get-ChildItem -Path 'Env:\' -Include 'INPUT_*' -Name | ForEach-Object -Process {
					[string]$InputKey = $_ -replace '^INPUT_', ''
					[string]$InputValue = Get-ChildItem -Path "Env:\INPUT_$InputKey"
					if ($Trim) {
						$Result[$InputKey] = $InputValue.Value.Trim()
					} else {
						$Result[$InputKey] = $InputValue.Value
					}
				}
				break
			}
			'select' {
				$Name | ForEach-Object -Process {
					if ([WildcardPattern]::ContainsWildcardCharacters($_)) {
						$ResultIsHashtable = $true
						Get-ChildItem -Path 'Env:\' -Include "INPUT_$_" -Name | ForEach-Object -Process {
							[string]$InputKey = $_ -replace '^INPUT_', ''
							[string]$InputValue = Get-ChildItem -Path "Env:\INPUT_$InputKey"
							if ($Trim) {
								$Result[$InputKey] = $InputValue.Value.Trim()
							} else {
								$Result[$InputKey] = $InputValue.Value
							}
						}
					} else {
						$InputValue = Get-ChildItem -Path "Env:\INPUT_$_" -ErrorAction SilentlyContinue
						if ($null -eq $InputValue) {
							if ($Require) {
								throw "Input ``$_`` is not defined!"
							}
							$Result[$_] = $InputValue
						} else {
							if ($Trim) {
								$Result[$_] = $InputValue.Value.Trim()
							} else {
								$Result[$_] = $InputValue.Value
							}
						}
					}
				}
				break
			}
		}
	}
	end {
		if (($ResultIsHashtable -eq $false) -and ($Result.Count -eq 1)) {
			return $Result.Values[0]
		}
		return $Result
	}
}
Set-Alias -Name 'Get-GHActionsInput' -Value 'Get-GitHubActionsInput' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Get Debug Status
.DESCRIPTION
Get debug status.
.OUTPUTS
Boolean
#>
function Get-GitHubActionsIsDebug {
	[CmdletBinding()][OutputType([bool])]
	param ()
	if ($env:RUNNER_DEBUG -eq 'true') {
		return $true
	}
	return $false
}
Set-Alias -Name 'Get-GHActionsIsDebug' -Value 'Get-GitHubActionsIsDebug' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Get State
.DESCRIPTION
Get state.
.PARAMETER Name
Name of the state.
.PARAMETER All
Get all of the state.
.PARAMETER Trim
Trim the state's value.
.OUTPUTS
Hashtable | String
#>
function Get-GitHubActionsState {
	[CmdletBinding(DefaultParameterSetName = 'select')][OutputType([hashtable], [string])]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'select', Position = 0, ValueFromPipeline = $true)][SupportsWildcards()][ValidatePattern('^.+$')][Alias('Key', 'Keys', 'Names')][string[]]$Name,
		[Parameter(ParameterSetName = 'all')][switch]$All,
		[switch]$Trim
	)
	begin {
		[hashtable]$Result = @{}
		[bool]$ResultIsHashtable = $false
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'all' {
				$ResultIsHashtable = $true
				Get-ChildItem -Path 'Env:\' -Include 'STATE_*' -Name | ForEach-Object -Process {
					[string]$StateKey = $_ -replace '^STATE_', ''
					[string]$StateValue = Get-ChildItem -Path "Env:\STATE_$StateKey"
					if ($Trim) {
						$Result[$StateKey] = $StateValue.Value.Trim()
					} else {
						$Result[$StateKey] = $StateValue.Value
					}
				}
				break
			}
			'select' {
				$Name | ForEach-Object -Process {
					if ([WildcardPattern]::ContainsWildcardCharacters($_)) {
						$ResultIsHashtable = $true
						Get-ChildItem -Path 'Env:\' -Include "STATE_$_" -Name | ForEach-Object -Process {
							[string]$StateKey = $_ -replace '^STATE_', ''
							[string]$StateValue = Get-ChildItem -Path "Env:\STATE_$StateKey"
							if ($Trim) {
								$Result[$StateKey] = $StateValue.Value.Trim()
							} else {
								$Result[$StateKey] = $StateValue.Value
							}
						}
					} else {
						$StateValue = Get-ChildItem -Path "Env:\STATE_$_" -ErrorAction SilentlyContinue
						if ($null -eq $StateValue) {
							$Result[$_] = $StateValue
						} else {
							if ($Trim) {
								$Result[$_] = $StateValue.Value.Trim()
							} else {
								$Result[$_] = $StateValue.Value
							}
						}
					}
				}
			}
		}
	}
	end {
		if ($Result.Count -eq 1) {
			return $Result.Values[0]
		}
		return $Result
	}
}
Set-Alias -Name 'Get-GHActionsState' -Value 'Get-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Restore-GHActionsState' -Value 'Get-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Restore-GitHubActionsState' -Value 'Get-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Get Webhook Event Payload
.DESCRIPTION
Get the complete webhook event payload.
.PARAMETER AsHashtable
Output as hashtable instead of object.
.PARAMETER Depth
Set the maximum depth the JSON input is allowed to have.
.PARAMETER NoEnumerate
Specify that output is not enumerated; Setting this parameter causes arrays to be sent as a single object instead of sending every element separately, this guarantees that JSON can be round-tripped via Cmdlet `ConvertTo-Json`.
.OUTPUTS
Hashtable | PSCustomObject
#>
function Get-GitHubActionsWebhookEventPayload {
	[CmdletBinding()][OutputType([hashtable], [pscustomobject])]
	param (
		[Alias('ToHashtable')][switch]$AsHashtable,
		[int]$Depth = 1024,
		[switch]$NoEnumerate
	)
	return ConvertFrom-Json -InputObject (Get-Content -Path $env:GITHUB_EVENT_PATH -Raw -Encoding 'UTF8NoBOM') -AsHashtable:$AsHashtable -Depth $Depth -NoEnumerate:$NoEnumerate
}
Set-Alias -Name 'Get-GHActionsEvent' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GHActionsPayload' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GHActionsWebhookEvent' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GHActionsWebhookEventPayload' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GHActionsWebhookPayload' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GitHubActionsEvent' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GitHubActionsPayload' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GitHubActionsWebhookEvent' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Get-GitHubActionsWebhookPayload' -Value 'Get-GitHubActionsWebhookEventPayload' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Remove Problem Matcher
.DESCRIPTION
Remove problem matcher that previously added from function `Add-GitHubActionsProblemMatcher`.
.PARAMETER Owner
Owner of the problem matcher that previously added from function `Add-GitHubActionsProblemMatcher`.
.OUTPUTS
Void
#>
function Remove-GitHubActionsProblemMatcher {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][ValidatePattern('^.+$')][Alias('Identifies', 'Identify', 'Identifier', 'Identifiers', 'Key', 'Keys', 'Name', 'Names', 'Owners')][string[]]$Owner
	)
	begin {}
	process {
		$Owner | ForEach-Object -Process {
			Write-GitHubActionsCommand -Command 'remove-matcher' -Message '' -Property @{ 'owner' = $_ }
		}
	}
	end {}
}
Set-Alias -Name 'Remove-GHActionsProblemMatcher' -Value 'Remove-GitHubActionsProblemMatcher' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Set Output
.DESCRIPTION
Set output.
.PARAMETER InputObject
Output.
.PARAMETER Name
Name of the output.
.PARAMETER Value
Value of the output.
.OUTPUTS
Void
#>
function Set-GitHubActionsOutput {
	[CmdletBinding(DefaultParameterSetName = 'multiple')][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'multiple', Position = 0, ValueFromPipeline = $true)][Alias('Input', 'Object')][hashtable]$InputObject,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 0)][ValidatePattern('^.+$')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 1)][string]$Value
	)
	begin {}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'multiple' {
				$InputObject.GetEnumerator() | ForEach-Object -Process {
					if ($_.Name.GetType().Name -ne 'string') {
						Write-Error -Message "Output name `"$($_.Name)`" must be type of string!" -Category InvalidType
					} elseif ($_.Name -notmatch '^.+$') {
						Write-Error -Message "Output name `"$($_.Name)`" is not match the require pattern!" -Category SyntaxError
					} elseif ($_.Value.GetType().Name -ne 'string') {
						Write-Error -Message "Output value `"$($_.Value)`" must be type of string!" -Category InvalidType
					} else {
						Write-GitHubActionsCommand -Command 'set-output' -Message $_.Value -Property @{ 'name' = $_.Name }
					}
				}
				break
			}
			'single' {
				Write-GitHubActionsCommand -Command 'set-output' -Message $Value -Property @{ 'name' = $Name }
				break
			}
		}
	}
	end {}
}
Set-Alias -Name 'Set-GHActionsOutput' -Value 'Set-GitHubActionsOutput' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Set State
.DESCRIPTION
Set state.
.PARAMETER InputObject
State.
.PARAMETER Name
Name of the state.
.PARAMETER Value
Value of the state.
.OUTPUTS
Void
#>
function Set-GitHubActionsState {
	[CmdletBinding(DefaultParameterSetName = 'multiple')][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'multiple', Position = 0, ValueFromPipeline = $true)][Alias('Input', 'Object')][hashtable]$InputObject,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 0)][ValidatePattern('^.+$')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 1)][string]$Value
	)
	begin {}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'multiple' {
				$InputObject.GetEnumerator() | ForEach-Object -Process {
					if ($_.Name.GetType().Name -ne 'string') {
						Write-Error -Message "State name `"$($_.Name)`" must be type of string!" -Category InvalidType
					} elseif ($_.Name -notmatch '^.+$') {
						Write-Error -Message "State name `"$($_.Name)`" is not match the require pattern!" -Category SyntaxError
					} elseif ($_.Value.GetType().Name -ne 'string') {
						Write-Error -Message "State value `"$($_.Value)`" must be type of string!" -Category InvalidType
					} else {
						Write-GitHubActionsCommand -Command 'save-state' -Message $_.Value -Property @{ 'name' = $_.Name }
					}
				}
				break
			}
			'single' {
				Write-GitHubActionsCommand -Command 'save-state' -Message $Value -Property @{ 'name' = $Name }
				break
			}
		}
	}
	end {}
}
Set-Alias -Name 'Save-GHActionsState' -Value 'Set-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Save-GitHubActionsState' -Value 'Set-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Set-GHActionsState' -Value 'Set-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Test Environment
.DESCRIPTION
Test the current process is executing inside the GitHub Actions environment.
.PARAMETER Force
Whether the requirement is force. If forced and not fulfill, will throw an error.
#>
function Test-GitHubActionsEnvironment {
	[CmdletBinding()][OutputType([bool])]
	param (
		[Alias('Forced', 'Require', 'Required')][switch]$Force
	)
	if (
		($env:CI -ne 'true') -or
		($env:GITHUB_ACTIONS -ne 'true') -or
		($null -eq $env:GITHUB_ACTION_PATH) -or
		($null -eq $env:GITHUB_ACTION_REPOSITORY) -or
		($null -eq $env:GITHUB_ACTION) -or
		($null -eq $env:GITHUB_ACTOR) -or
		($null -eq $env:GITHUB_API_URL) -or
		($null -eq $env:GITHUB_ENV) -or
		($null -eq $env:GITHUB_EVENT_NAME) -or
		($null -eq $env:GITHUB_EVENT_PATH) -or
		($null -eq $env:GITHUB_GRAPHQL_URL) -or
		($null -eq $env:GITHUB_JOB) -or
		($null -eq $env:GITHUB_PATH) -or
		($null -eq $env:GITHUB_REF_NAME) -or
		($null -eq $env:GITHUB_REF_PROTECTED) -or
		($null -eq $env:GITHUB_REF_TYPE) -or
		($null -eq $env:GITHUB_REPOSITORY_OWNER) -or
		($null -eq $env:GITHUB_REPOSITORY) -or
		($null -eq $env:GITHUB_RETENTION_DAYS) -or
		($null -eq $env:GITHUB_RUN_ATTEMPT) -or
		($null -eq $env:GITHUB_RUN_ID) -or
		($null -eq $env:GITHUB_RUN_NUMBER) -or
		($null -eq $env:GITHUB_SERVER_URL) -or
		($null -eq $env:GITHUB_SHA) -or
		($null -eq $env:GITHUB_WORKFLOW) -or
		($null -eq $env:GITHUB_WORKSPACE) -or
		($null -eq $env:RUNNER_ARCH) -or
		($null -eq $env:RUNNER_NAME) -or
		($null -eq $env:RUNNER_OS) -or
		($null -eq $env:RUNNER_TEMP) -or
		($null -eq $env:RUNNER_TOOL_CACHE)
	) {
		if ($Force) {
			throw 'This process require to execute inside the GitHub Actions environment.'
		}
		return $false
	}
	return $true
}
Set-Alias -Name 'Test-GHActionsEnvironment' -Value 'Test-GitHubActionsEnvironment' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Write Annotation
.DESCRIPTION
Prints an annotation message to the log.
.PARAMETER Type
Annotation type.
.PARAMETER Message
Message that need to log at annotation.
.PARAMETER File
Issue file path.
.PARAMETER Line
Issue file line start.
.PARAMETER Column
Issue file column start.
.PARAMETER EndLine
Issue file line end.
.PARAMETER EndColumn
Issue file column end.
.PARAMETER Title
Issue title.
.OUTPUTS
Void
#>
function Write-GitHubActionsAnnotation {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][GitHubActionsAnnotationType]$Type,
		[Parameter(Mandatory = $true, Position = 1)][Alias('Content')][string]$Message,
		[ValidatePattern('^.*$')][Alias('Path')][string]$File,
		[Alias('LineStart', 'StartLine')][uint]$Line,
		[Alias('Col', 'ColStart', 'ColumnStart', 'StartCol', 'StartColumn')][uint]$Column,
		[Alias('LineEnd')][uint]$EndLine,
		[Alias('ColEnd', 'ColumnEnd', 'EndCol')][uint]$EndColumn,
		[ValidatePattern('^.*$')][Alias('Header')][string]$Title
	)
	[string]$TypeRaw = ""
	switch ($Type.GetHashCode()) {
		0 {
			$TypeRaw = 'notice'
			break
		}
		1 {
			$TypeRaw = 'warning'
			break
		}
		2 {
			$TypeRaw = 'error'
			break
		}
	}
	[hashtable]$Property = @{}
	if ($File.Length -gt 0) {
		$Property.'file' = $File
	}
	if ($Line -gt 0) {
		$Property.'line' = $Line
	}
	if ($Column -gt 0) {
		$Property.'col' = $Column
	}
	if ($EndLine -gt 0) {
		$Property.'endLine' = $EndLine
	}
	if ($EndColumn -gt 0) {
		$Property.'endColumn' = $EndColumn
	}
	if ($Title.Length -gt 0) {
		$Property.'title' = $Title
	}
	Write-GitHubActionsCommand -Command $TypeRaw -Message $Message -Property $Property
}
Set-Alias -Name 'Write-GHActionsAnnotation' -Value 'Write-GitHubActionsAnnotation' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Write Debug
.DESCRIPTION
Prints a debug message to the log.
.PARAMETER Message
Message that need to log at debug level.
.OUTPUTS
Void
#>
function Write-GitHubActionsDebug {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][Alias('Content')][string]$Message
	)
	begin {}
	process {
		Write-GitHubActionsCommand -Command 'debug' -Message $Message
	}
	end {}
}
Set-Alias -Name 'Write-GHActionsDebug' -Value 'Write-GitHubActionsDebug' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Write Error
.DESCRIPTION
Prints an error message to the log.
.PARAMETER Message
Message that need to log at error level.
.PARAMETER File
Issue file path.
.PARAMETER Line
Issue file line start.
.PARAMETER Col
Issue file column start.
.PARAMETER EndLine
Issue file line end.
.PARAMETER EndColumn
Issue file column end.
.PARAMETER Title
Issue title.
.OUTPUTS
Void
#>
function Write-GitHubActionsError {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][Alias('Content')][string]$Message,
		[ValidatePattern('^.*$')][Alias('Path')][string]$File,
		[Alias('LineStart', 'StartLine')][uint]$Line,
		[Alias('Col', 'ColStart', 'ColumnStart', 'StartCol', 'StartColumn')][uint]$Column,
		[Alias('LineEnd')][uint]$EndLine,
		[Alias('ColEnd', 'ColumnEnd', 'EndCol')][uint]$EndColumn,
		[ValidatePattern('^.*$')][Alias('Header')][string]$Title
	)
	Write-GitHubActionsAnnotation -Type 'Error' -Message $Message -File $File -Line $Line -Column $Column -EndLine $EndLine -EndColumn $EndColumn -Title $Title
}
Set-Alias -Name 'Write-GHActionsError' -Value 'Write-GitHubActionsError' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Write Fail
.DESCRIPTION
Prints an error message to the log and end the process.
.PARAMETER Message
Message that need to log at error level.
.PARAMETER File
Issue file path.
.PARAMETER Line
Issue file line start.
.PARAMETER Col
Issue file column start.
.PARAMETER EndLine
Issue file line end.
.PARAMETER EndColumn
Issue file column end.
.PARAMETER Title
Issue title.
.OUTPUTS
Void
#>
function Write-GitHubActionsFail {
	[CmdletBinding()][OutputType([void])]
	param(
		[Parameter(Mandatory = $true, Position = 0)][Alias('Content')][string]$Message,
		[ValidatePattern('^.*$')][Alias('Path')][string]$File,
		[Alias('LineStart', 'StartLine')][uint]$Line,
		[Alias('Col', 'ColStart', 'ColumnStart', 'StartCol', 'StartColumn')][uint]$Column,
		[Alias('LineEnd')][uint]$EndLine,
		[Alias('ColEnd', 'ColumnEnd', 'EndCol')][uint]$EndColumn,
		[ValidatePattern('^.*$')][Alias('Header')][string]$Title
	)
	Write-GitHubActionsAnnotation -Type 'Error' -Message $Message -File $File -Line $Line -Column $Column -EndLine $EndLine -EndColumn $EndColumn -Title $Title
	exit 1
}
Set-Alias -Name 'Write-GHActionsFail' -Value 'Write-GitHubActionsFail' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Write Notice
.DESCRIPTION
Prints a notice message to the log.
.PARAMETER Message
Message that need to log at notice level.
.PARAMETER File
Issue file path.
.PARAMETER Line
Issue file line start.
.PARAMETER Col
Issue file column start.
.PARAMETER EndLine
Issue file line end.
.PARAMETER EndColumn
Issue file column end.
.PARAMETER Title
Issue title.
.OUTPUTS
Void
#>
function Write-GitHubActionsNotice {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][Alias('Content')][string]$Message,
		[ValidatePattern('^.*$')][Alias('Path')][string]$File,
		[Alias('LineStart', 'StartLine')][uint]$Line,
		[Alias('Col', 'ColStart', 'ColumnStart', 'StartCol', 'StartColumn')][uint]$Column,
		[Alias('LineEnd')][uint]$EndLine,
		[Alias('ColEnd', 'ColumnEnd', 'EndCol')][uint]$EndColumn,
		[ValidatePattern('^.*$')][Alias('Header')][string]$Title
	)
	Write-GitHubActionsAnnotation -Type 'Notice' -Message $Message -File $File -Line $Line -Column $Column -EndLine $EndLine -EndColumn $EndColumn -Title $Title
}
Set-Alias -Name 'Write-GHActionsNote' -Value 'Write-GitHubActionsNotice' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Write-GHActionsNotice' -Value 'Write-GitHubActionsNotice' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Write-GitHubActionsNote' -Value 'Write-GitHubActionsNotice' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Write Warning
.DESCRIPTION
Prints a warning message to the log.
.PARAMETER Message
Message that need to log at warning level.
.PARAMETER File
Issue file path.
.PARAMETER Line
Issue file line start.
.PARAMETER Col
Issue file column start.
.PARAMETER EndLine
Issue file line end.
.PARAMETER EndColumn
Issue file column end.
.PARAMETER Title
Issue title.
.OUTPUTS
Void
#>
function Write-GitHubActionsWarning {
	[CmdletBinding()][OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][Alias('Content')][string]$Message,
		[ValidatePattern('^.*$')][Alias('Path')][string]$File,
		[Alias('LineStart', 'StartLine')][uint]$Line,
		[Alias('Col', 'ColStart', 'ColumnStart', 'StartCol', 'StartColumn')][uint]$Column,
		[Alias('LineEnd')][uint]$EndLine,
		[Alias('ColEnd', 'ColumnEnd', 'EndCol')][uint]$EndColumn,
		[ValidatePattern('^.*$')][Alias('Header')][string]$Title
	)
	Write-GitHubActionsAnnotation -Type 'Warning' -Message $Message -File $File -Line $Line -Column $Column -EndLine $EndLine -EndColumn $EndColumn -Title $Title
}
Set-Alias -Name 'Write-GHActionsWarn' -Value 'Write-GitHubActionsWarning' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Write-GHActionsWarning' -Value 'Write-GitHubActionsWarning' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Write-GitHubActionsWarn' -Value 'Write-GitHubActionsWarning' -Option 'ReadOnly' -Scope 'Local'
Export-ModuleMember -Function @(
	'Add-GitHubActionsEnvironmentVariable',
	'Add-GitHubActionsPATH',
	'Add-GitHubActionsProblemMatcher',
	'Add-GitHubActionsSecretMask',
	'Disable-GitHubActionsEchoCommand',
	'Disable-GitHubActionsProcessingCommand',
	'Enable-GitHubActionsEchoCommand',
	'Enable-GitHubActionsProcessingCommand',
	'Enter-GitHubActionsLogGroup',
	'Exit-GitHubActionsLogGroup',
	'Get-GitHubActionsInput',
	'Get-GitHubActionsIsDebug',
	'Get-GitHubActionsState',
	'Get-GitHubActionsWebhookEventPayload',
	'Remove-GitHubActionsProblemMatcher',
	'Set-GitHubActionsOutput',
	'Set-GitHubActionsState',
	'Test-GitHubActionsEnvironment',
	'Write-GitHubActionsAnnotation',
	'Write-GitHubActionsCommand',
	'Write-GitHubActionsDebug',
	'Write-GitHubActionsError',
	'Write-GitHubActionsFail',
	'Write-GitHubActionsNotice',
	'Write-GitHubActionsWarning'
) -Alias @(
	'Add-GHActionsEnv',
	'Add-GHActionsEnvironment',
	'Add-GHActionsEnvironmentVariable',
	'Add-GHActionsMask',
	'Add-GHActionsPATH',
	'Add-GHActionsProblemMatcher',
	'Add-GHActionsSecret',
	'Add-GitHubActionsEnv',
	'Add-GitHubActionsEnvironment',
	'Add-GitHubActionsMask',
	'Add-GitHubActionsSecret',
	'Disable-GHActionsCommandEcho',
	'Disable-GHActionsCommandProcessing',
	'Disable-GHActionsEchoCommand',
	'Disable-GHActionsProcessingCommand',
	'Disable-GitHubActionsCommandEcho',
	'Disable-GitHubActionsCommandProcessing',
	'Enable-GHActionsCommandEcho',
	'Enable-GHActionsCommandProcessing',
	'Enable-GHActionsEchoCommand',
	'Enable-GHActionsProcessingCommand',
	'Enable-GitHubActionsCommandEcho',
	'Enable-GitHubActionsCommandProcessing',
	'Enter-GHActionsGroup',
	'Enter-GHActionsLogGroup',
	'Enter-GitHubActionsGroup',
	'Exit-GHActionsGroup',
	'Exit-GHActionsLogGroup',
	'Exit-GitHubActionsGroup',
	'Get-GHActionsEvent',
	'Get-GHActionsInput',
	'Get-GHActionsIsDebug',
	'Get-GHActionsPayload',
	'Get-GHActionsState',
	'Get-GHActionsWebhookEvent',
	'Get-GHActionsWebhookEventPayload',
	'Get-GHActionsWebhookPayload',
	'Get-GitHubActionsEvent',
	'Get-GitHubActionsPayload',
	'Get-GitHubActionsWebhookEvent',
	'Get-GitHubActionsWebhookPayload',
	'Remove-GHActionsProblemMatcher',
	'Restore-GHActionsState',
	'Restore-GitHubActionsState',
	'Save-GHActionsState',
	'Save-GitHubActionsState',
	'Set-GHActionsOutput',
	'Set-GHActionsState',
	'Test-GHActionsEnvironment',
	'Write-GHActionsAnnotation',
	'Write-GHActionsCommand',
	'Write-GHActionsDebug',
	'Write-GHActionsError',
	'Write-GHActionsFail',
	'Write-GHActionsNote',
	'Write-GHActionsNotice',
	'Write-GHActionsWarn',
	'Write-GHActionsWarning',
	'Write-GitHubActionsNote',
	'Write-GitHubActionsWarn'
)
