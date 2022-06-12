#Requires -PSEdition Core
#Requires -Version 7.2
[string]$ModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath 'module'
Import-Module -Name @(
	(Join-Path -Path $ModuleRoot -ChildPath 'command.psm1'),
	(Join-Path -Path $ModuleRoot -ChildPath 'log.psm1'),
	(Join-Path -Path $ModuleRoot -ChildPath 'oidc.psm1'),
	(Join-Path -Path $ModuleRoot -ChildPath 'problem-matcher.psm1'),
	(Join-Path -Path $ModuleRoot -ChildPath 'step-summary.psm1')
) -Scope 'Local'
enum PowerShellEnvironmentVariableScope {
	Process = 0
	P = 0
	User = 1
	U = 1
	System = 2
	S = 2
}
<#
.SYNOPSIS
GitHub Actions (Internal) - Add Local Environment Variable
.DESCRIPTION
Add local environment variable.
.PARAMETER Name
Environment variable name.
.PARAMETER Value
Environment variable value.
.PARAMETER NoClobber
Prevent to add environment variables that exist in the current step.
.PARAMETER Scope
Scope to add environment variables.
.OUTPUTS
Void
#>
function Add-GitHubActionsLocalEnvironmentVariable {
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, Position = 1)][string]$Value,
		[Alias('NoOverride', 'NoOverwrite')][switch]$NoClobber,
		[PowerShellEnvironmentVariableScope]$Scope = 'Process'
	)
	[string]$NameUpper = $Name.ToUpper()
	if ($NoClobber -and $null -ne (Get-ChildItem -LiteralPath "Env:\$NameUpper" -ErrorAction 'SilentlyContinue')) {
		return Write-Error -Message "Environment variable ``$Name`` is exists in current step (no clobber)!" -Category 'ResourceExists'
	}
	switch ($Scope.GetHashCode()) {
		0 {
			return [System.Environment]::SetEnvironmentVariable($NameUpper, $Value, 'Process')
		}
		1 {
			return [System.Environment]::SetEnvironmentVariable($NameUpper, $Value, 'User')
		}
		2 {
			return [System.Environment]::SetEnvironmentVariable($NameUpper, $Value, 'Machine')
		}
	}
}
Set-Alias -Name 'Add-GHActionsLocalEnv' -Value 'Add-GitHubActionsLocalEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GHActionsLocalEnvironment' -Value 'Add-GitHubActionsLocalEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GHActionsLocalEnvironmentVariable' -Value 'Add-GitHubActionsLocalEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GitHubActionsLocalEnv' -Value 'Add-GitHubActionsLocalEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Add-GitHubActionsLocalEnvironment' -Value 'Add-GitHubActionsLocalEnvironmentVariable' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions (Internal) - Add Local PATH
.DESCRIPTION
Add local PATH.
.PARAMETER Path
Path.
.PARAMETER Scope
Scope to add PATH.
.OUTPUTS
Void
#>
function Add-GitHubActionsLocalPATH {
	[CmdletBinding()]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0)][Alias('Paths')][string[]]$Path,
		[PowerShellEnvironmentVariableScope]$Scope = 'Process'
	)
	[string]$PATHOriginalRaw = ''
	switch ($Scope.GetHashCode()) {
		0 {
			$PATHOriginalRaw = [System.Environment]::GetEnvironmentVariable('PATH', 'Process')
		}
		1 {
			$PATHOriginalRaw = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
		}
		2 {
			$PATHOriginalRaw = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
		}
	}
	[string[]]$PATHOriginal = $PATHOriginalRaw -split [System.IO.Path]::PathSeparator
	[string[]]$PATHNew = @()
	foreach($Item in $Path) {
		if ($Item -inotin $PATHOriginal) {
			$PATHNew += $Item
		}
	}
	return Add-GitHubActionsLocalEnvironmentVariable -Name 'PATH' -Value (($PATHNew + $PATHOriginal) -join [System.IO.Path]::PathSeparator) -Scope $Scope
}
<#
.SYNOPSIS
GitHub Actions - Add Environment Variable
.DESCRIPTION
Add environment variable to all subsequent steps in the current job.
.PARAMETER InputObject
Environment variables.
.PARAMETER Name
Environment variable name.
.PARAMETER Value
Environment variable value.
.PARAMETER NoClobber
Prevent to add environment variables that exist in the current step, or all subsequent steps in the current job.
.PARAMETER WithLocal
Also add to the current step.
.PARAMETER LocalScope
Local scope to add environment variables.
.OUTPUTS
Void
#>
function Add-GitHubActionsEnvironmentVariable {
	[CmdletBinding(DefaultParameterSetName = 'multiple', HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_add-githubactionsenvironmentvariable#Add-GitHubActionsEnvironmentVariable')]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'multiple', Position = 0, ValueFromPipeline = $true)][Alias('Input', 'Object')][hashtable]$InputObject,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 0, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^(?:[\da-z][\da-z_-]*)?[\da-z]$', ErrorMessage = '`{0}` is not a valid environment variable name!')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 1, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^.+$', ErrorMessage = 'Parameter `Value` must be in single line string!')][string]$Value,
		[Alias('NoOverride', 'NoOverwrite')][switch]$NoClobber,
		[Alias('WithCurrent')][switch]$WithLocal,
		[Alias('LocalEnvironmentVariableScope')][PowerShellEnvironmentVariableScope]$LocalScope = 'Process'
	)
	begin {
		[hashtable]$Original = ConvertFrom-StringData -StringData (Get-Content -LiteralPath $env:GITHUB_ENV -Raw -Encoding 'UTF8NoBOM')
		[hashtable]$Result = @{}
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'multiple' {
				foreach ($Item in $InputObject.GetEnumerator()) {
					if ($Item.Name.GetType().Name -ne 'string') {
						Write-Error -Message 'Parameter `Name` must be type of string!' -Category 'InvalidType'
						continue
					}
					if ($Item.Name -notmatch '^(?:[\da-z][\da-z_-]*)?[\da-z]$') {
						Write-Error -Message "``$($Item.Name)`` is not a valid environment variable name!" -Category 'SyntaxError'
						continue
					}
					if ($Item.Value.GetType().Name -ne 'string') {
						Write-Error -Message 'Parameter `Value` must be type of string!' -Category 'InvalidType'
						continue
					}
					if ($Item.Value -notmatch '^.+$') {
						Write-Error -Message 'Parameter `Value` must be in single line string!' -Category 'SyntaxError'
						continue
					}
					[string]$ItemNameUpper = $Item.Name.ToUpper()
					if ($NoClobber -and $null -ne $Original[$ItemNameUpper]) {
						Write-Error -Message "Environment variable ``$($Item.Name)`` is exists in all subsequent steps (no clobber)!" -Category 'ResourceExists'
					} else {
						$Result[$ItemNameUpper] = $Item.Value
					}
					if ($WithLocal) {
						Add-LocalEnvironmentVariable -Name $ItemNameUpper -Value $Item.Value -NoClobber:$NoClobber -LocalScope $LocalScope
					}
				}
				break
			}
			'single' {
				[string]$NameUpper = $Name.ToUpper()
				if ($NoClobber -and $null -ne $Original[$NameUpper]) {
					Write-Error -Message "Environment variable ``$Name`` is exists in all subsequent steps (no clobber)!" -Category 'ResourceExists'
				} else {
					$Result[$NameUpper] = $Value
				}
				if ($WithLocal) {
					Add-LocalEnvironmentVariable -Name $NameUpper -Value $Value -NoClobber:$NoClobber -LocalScope $LocalScope
				}
				break
			}
		}
	}
	end {
		if ($Result.Count -gt 0) {
			Add-Content -LiteralPath $env:GITHUB_ENV -Value (($Result.GetEnumerator() | ForEach-Object -Process {
				return "$($_.Name)=$($_.Value)"
			}) -join "`n") -Confirm:$false -Encoding 'UTF8NoBOM'
		}
		return
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
Add PATH to all subsequent steps in the current job.
.PARAMETER Path
Path.
.PARAMETER NoValidator
Disable validator to not check the path is valid or not.
.PARAMETER WithLocal
Also add to the current step.
.PARAMETER LocalScope
Local scope to add PATH.
.OUTPUTS
Void
#>
function Add-GitHubActionsPATH {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_add-githubactionspath#Add-GitHubActionsPATH')]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^.+$', ErrorMessage = 'Parameter `Path` must be in single line string!')][Alias('Paths')][string[]]$Path,
		[Alias('NoValidate', 'SkipValidate', 'SkipValidator')][switch]$NoValidator,
		[Alias('WithCurrent')][switch]$WithLocal,
		[Alias('LocalPATHScope')][PowerShellEnvironmentVariableScope]$LocalScope = 'Process'
	)
	begin {
		[string[]]$Result = @()
	}
	process {
		foreach ($Item in $Path) {
			if ($Item -inotin $Result) {
				if (
					$NoValidator -or
					(Test-Path -Path $Item -PathType 'Container' -IsValid)
				) {
					$Result += $Item
				} else {
					Write-Error -Message "``$Item`` is not a valid PATH!" -Category 'SyntaxError'
				}
			}
		}
	}
	end {
		if ($Result.Count -gt 0) {
			Add-Content -LiteralPath $env:GITHUB_PATH -Value ($Result -join "`n") -Confirm:$false -Encoding 'UTF8NoBOM'
		}
		return
	}
}
Set-Alias -Name 'Add-GHActionsPATH' -Value 'Add-GitHubActionsPATH' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Get Input
.DESCRIPTION
Get input.
.PARAMETER Name
Name of the input.
.PARAMETER Require
Whether the input is require; If required and not present, will throw an error.
.PARAMETER RequireFailMessage
The error message when the input is required and not present.
.PARAMETER NamePrefix
Name of the inputs start with.
.PARAMETER NameSuffix
Name of the inputs end with.
.PARAMETER All
Get all of the inputs.
.PARAMETER Trim
Trim the input's value.
.OUTPUTS
Hashtable | String
#>
function Get-GitHubActionsInput {
	[CmdletBinding(DefaultParameterSetName = 'one', HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_get-githubactionsinput#Get-GitHubActionsInput')]
	[OutputType([string], ParameterSetName = 'one')]
	[OutputType([hashtable], ParameterSetName = ('all', 'prefix', 'suffix'))]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'one', Position = 0, ValueFromPipeline = $true)][ValidatePattern('^(?:[\da-z][\da-z_-]*)?[\da-z]$', ErrorMessage = '`{0}` is not a valid GitHub Actions input name!')][Alias('Key')][string]$Name,
		[Parameter(ParameterSetName = 'one')][Alias('Force', 'Forced', 'Required')][switch]$Require,
		[Parameter(ParameterSetName = 'one')][Alias('ErrorMessage', 'FailMessage', 'RequireErrorMessage')][string]$RequireFailMessage = 'Input `{0}` is not defined!',
		[Parameter(Mandatory = $true, ParameterSetName = 'prefix')][ValidatePattern('^[\da-z][\da-z_-]*$', ErrorMessage = '`{0}` is not a valid GitHub Actions input name prefix!')][Alias('KeyPrefix', 'KeyStartWith', 'NameStartWith', 'Prefix', 'PrefixKey', 'PrefixName', 'StartWith', 'StartWithKey', 'StartWithName')][string]$NamePrefix,
		[Parameter(Mandatory = $true, ParameterSetName = 'suffix')][ValidatePattern('^[\da-z_-]*[\da-z]$', ErrorMessage = '`{0}` is not a valid GitHub Actions input name suffix!')][Alias('EndWith', 'EndWithKey', 'EndWithName', 'KeyEndWith', 'KeySuffix', 'NameEndWith', 'Suffix', 'SuffixKey', 'SuffixName')][string]$NameSuffix,
		[Parameter(ParameterSetName = 'all')][switch]$All,
		[switch]$Trim
	)
	begin {
		[hashtable]$OutputObject = @{}
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'all' {
				Get-ChildItem -Path 'Env:\INPUT_*' | ForEach-Object -Process {
					[string]$InputKey = $_.Name -replace '^INPUT_', ''
					if ($Trim) {
						$OutputObject[$InputKey] = $_.Value.Trim()
					} else {
						$OutputObject[$InputKey] = $_.Value
					}
				}
				break
			}
			'one' {
				$InputValue = Get-ChildItem -LiteralPath "Env:\INPUT_$($Name.ToUpper())" -ErrorAction 'SilentlyContinue'
				if ($null -eq $InputValue) {
					if ($Require) {
						return Write-GitHubActionsFail -Message ($RequireFailMessage -f $Name)
					}
					return $null
				}
				if ($Trim) {
					return $InputValue.Value.Trim()
				}
				return $InputValue.Value
			}
			'prefix' {
				Get-ChildItem -Path "Env:\INPUT_$($NamePrefix.ToUpper())*" | ForEach-Object -Process {
					[string]$InputKey = $_.Name -replace "^INPUT_$([regex]::Escape($NamePrefix))", ''
					if ($Trim) {
						$OutputObject[$InputKey] = $_.Value.Trim()
					} else {
						$OutputObject[$InputKey] = $_.Value
					}
				}
				break
			}
			'suffix' {
				Get-ChildItem -Path "Env:\INPUT_*$($NameSuffix.ToUpper())" | ForEach-Object -Process {
					[string]$InputKey = $_.Name -replace "^INPUT_|$([regex]::Escape($NameSuffix))$", ''
					if ($Trim) {
						$OutputObject[$InputKey] = $_.Value.Trim()
					} else {
						$OutputObject[$InputKey] = $_.Value
					}
				}
				break
			}
		}
	}
	end {
		if ($PSCmdlet.ParameterSetName -iin @('all', 'prefix', 'suffix')) {
			return $OutputObject
		}
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
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_get-githubactionsisdebug#Get-GitHubActionsIsDebug')]
	[OutputType([bool])]
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
.PARAMETER NamePrefix
Name of the states start with.
.PARAMETER NameSuffix
Name of the states end with.
.PARAMETER All
Get all of the states.
.PARAMETER Trim
Trim the state's value.
.OUTPUTS
Hashtable | String
#>
function Get-GitHubActionsState {
	[CmdletBinding(DefaultParameterSetName = 'one', HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_get-githubactionsstate#Get-GitHubActionsState')]
	[OutputType([string], ParameterSetName = 'one')]
	[OutputType([hashtable], ParameterSetName = ('all', 'prefix', 'suffix'))]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'one', Position = 0, ValueFromPipeline = $true)][ValidatePattern('^(?:[\da-z][\da-z_-]*)?[\da-z]$', ErrorMessage = '`{0}` is not a valid GitHub Actions state name!')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'prefix')][ValidatePattern('^[\da-z][\da-z_-]*$', ErrorMessage = '`{0}` is not a valid GitHub Actions state name prefix!')][Alias('KeyPrefix', 'KeyStartWith', 'NameStartWith', 'Prefix', 'PrefixKey', 'PrefixName', 'StartWith', 'StartWithKey', 'StartWithName')][string]$NamePrefix,
		[Parameter(Mandatory = $true, ParameterSetName = 'suffix')][ValidatePattern('^[\da-z_-]*[\da-z]$', ErrorMessage = '`{0}` is not a valid GitHub Actions state name suffix!')][Alias('EndWith', 'EndWithKey', 'EndWithName', 'KeyEndWith', 'KeySuffix', 'NameEndWith', 'Suffix', 'SuffixKey', 'SuffixName')][string]$NameSuffix,
		[Parameter(ParameterSetName = 'all')][switch]$All,
		[switch]$Trim
	)
	begin {
		[hashtable]$OutputObject = @{}
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'all' {
				Get-ChildItem -Path 'Env:\STATE_*' | ForEach-Object -Process {
					[string]$StateKey = $_.Name -replace '^STATE_', ''
					if ($Trim) {
						$OutputObject[$StateKey] = $_.Value.Trim()
					} else {
						$OutputObject[$StateKey] = $_.Value
					}
				}
				break
			}
			'one' {
				$StateValue = Get-ChildItem -LiteralPath "Env:\STATE_$($Name.ToUpper())" -ErrorAction 'SilentlyContinue'
				if ($null -eq $StateValue) {
					return $null
				}
				if ($Trim) {
					return $StateValue.Value.Trim()
				}
				return $StateValue.Value
			}
			'prefix' {
				Get-ChildItem -Path "Env:\STATE_$($NamePrefix.ToUpper())*" | ForEach-Object -Process {
					[string]$StateKey = $_.Name -replace "^STATE_$([regex]::Escape($NamePrefix))", ''
					if ($Trim) {
						$OutputObject[$StateKey] = $_.Value.Trim()
					} else {
						$OutputObject[$StateKey] = $_.Value
					}
				}
				break
			}
			'suffix' {
				Get-ChildItem -Path "Env:\STATE_*$($NameSuffix.ToUpper())" | ForEach-Object -Process {
					[string]$StateKey = $_.Name -replace "^STATE_|$([regex]::Escape($NameSuffix))$", ''
					if ($Trim) {
						$OutputObject[$StateKey] = $_.Value.Trim()
					} else {
						$OutputObject[$StateKey] = $_.Value
					}
				}
				break
			}
		}
	}
	end {
		if ($PSCmdlet.ParameterSetName -iin @('all', 'prefix', 'suffix')) {
			return $OutputObject
		}
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
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_get-githubactionswebhookeventpayload#Get-GitHubActionsWebhookEventPayload')]
	[OutputType(([hashtable], [pscustomobject]))]
	param (
		[Alias('ToHashtable')][switch]$AsHashtable,
		[int]$Depth = 1024,
		[switch]$NoEnumerate
	)
	return (Get-Content -LiteralPath $env:GITHUB_EVENT_PATH -Raw -Encoding 'UTF8NoBOM' | ConvertFrom-Json -AsHashtable:$AsHashtable -Depth $Depth -NoEnumerate:$NoEnumerate)
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
GitHub Actions - Set Output
.DESCRIPTION
Set output.
.PARAMETER InputObject
Outputs.
.PARAMETER Name
Name of the output.
.PARAMETER Value
Value of the output.
.OUTPUTS
Void
#>
function Set-GitHubActionsOutput {
	[CmdletBinding(DefaultParameterSetName = 'multiple', HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_set-githubactionsoutput#Set-GitHubActionsOutput')]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'multiple', Position = 0, ValueFromPipeline = $true)][Alias('Input', 'Object')][hashtable]$InputObject,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 0, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^(?:[\da-z][\da-z_-]*)?[\da-z]$', ErrorMessage = '`{0}` is not a valid GitHub Actions output name!')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 1, ValueFromPipelineByPropertyName = $true)][AllowEmptyString()][string]$Value
	)
	begin {}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'multiple' {
				$InputObject.GetEnumerator() | ForEach-Object -Process {
					if ($_.Name.GetType().Name -ne 'string') {
						Write-Error -Message 'Parameter `Name` must be type of string!' -Category InvalidType
					} elseif ($_.Name -notmatch '^(?:[\da-z][\da-z_-]*)?[\da-z]$') {
						Write-Error -Message "``$($_.Name)`` is not a valid GitHub Actions output name!" -Category SyntaxError
					} elseif ($_.Value.GetType().Name -ne 'string') {
						Write-Error -Message 'Parameter `Value` must be type of string!' -Category InvalidType
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
	end {
		return
	}
}
Set-Alias -Name 'Set-GHActionsOutput' -Value 'Set-GitHubActionsOutput' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Set State
.DESCRIPTION
Set state.
.PARAMETER InputObject
States.
.PARAMETER Name
Name of the state.
.PARAMETER Value
Value of the state.
.OUTPUTS
Void
#>
function Set-GitHubActionsState {
	[CmdletBinding(DefaultParameterSetName = 'multiple', HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_set-githubactionsstate#Set-GitHubActionsState')]
	[OutputType([void])]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'multiple', Position = 0, ValueFromPipeline = $true)][Alias('Input', 'Object')][hashtable]$InputObject,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 0, ValueFromPipelineByPropertyName = $true)][ValidatePattern('^(?:[\da-z][\da-z_-]*)?[\da-z]$', ErrorMessage = '`{0}` is not a valid GitHub Actions state name!')][Alias('Key')][string]$Name,
		[Parameter(Mandatory = $true, ParameterSetName = 'single', Position = 1, ValueFromPipelineByPropertyName = $true)][AllowEmptyString()][string]$Value
	)
	begin {}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'multiple' {
				$InputObject.GetEnumerator() | ForEach-Object -Process {
					if ($_.Name.GetType().Name -ne 'string') {
						Write-Error -Message 'Parameter `Name` must be type of string!' -Category InvalidType
					} elseif ($_.Name -notmatch '^(?:[\da-z][\da-z_-]*)?[\da-z]$') {
						Write-Error -Message "``$($_.Name)`` is not a valid GitHub Actions state name!" -Category SyntaxError
					} elseif ($_.Value.GetType().Name -ne 'string') {
						Write-Error -Message 'Parameter `Value` must be type of string!' -Category InvalidType
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
	end {
		return
	}
}
Set-Alias -Name 'Save-GHActionsState' -Value 'Set-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Save-GitHubActionsState' -Value 'Set-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
Set-Alias -Name 'Set-GHActionsState' -Value 'Set-GitHubActionsState' -Option 'ReadOnly' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Test Environment
.DESCRIPTION
Test the current process is executing inside the GitHub Actions environment.
.PARAMETER Require
Whether the requirement is require; If required and not fulfill, will throw an error.
#>
function Test-GitHubActionsEnvironment {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_test-githubactionsenvironment#Test-GitHubActionsEnvironment')]
	[OutputType([bool])]
	param (
		[Alias('Force', 'Forced', 'Required')][switch]$Require
	)
	if (
		$env:CI -ne 'true' -or
		$null -eq $env:GITHUB_ACTION_REPOSITORY -or
		$null -eq $env:GITHUB_ACTION -or
		$null -eq $env:GITHUB_ACTIONS -or
		$null -eq $env:GITHUB_ACTOR -or
		$null -eq $env:GITHUB_API_URL -or
		$null -eq $env:GITHUB_ENV -or
		$null -eq $env:GITHUB_EVENT_NAME -or
		$null -eq $env:GITHUB_EVENT_PATH -or
		$null -eq $env:GITHUB_GRAPHQL_URL -or
		$null -eq $env:GITHUB_JOB -or
		$null -eq $env:GITHUB_PATH -or
		$null -eq $env:GITHUB_REF_NAME -or
		$null -eq $env:GITHUB_REF_PROTECTED -or
		$null -eq $env:GITHUB_REF_TYPE -or
		$null -eq $env:GITHUB_REPOSITORY_OWNER -or
		$null -eq $env:GITHUB_REPOSITORY -or
		$null -eq $env:GITHUB_RETENTION_DAYS -or
		$null -eq $env:GITHUB_RUN_ATTEMPT -or
		$null -eq $env:GITHUB_RUN_ID -or
		$null -eq $env:GITHUB_RUN_NUMBER -or
		$null -eq $env:GITHUB_SERVER_URL -or
		$null -eq $env:GITHUB_SHA -or
		$null -eq $env:GITHUB_STEP_SUMMARY -or
		$null -eq $env:GITHUB_WORKFLOW -or
		$null -eq $env:GITHUB_WORKSPACE -or
		$null -eq $env:RUNNER_ARCH -or
		$null -eq $env:RUNNER_NAME -or
		$null -eq $env:RUNNER_OS -or
		$null -eq $env:RUNNER_TEMP -or
		$null -eq $env:RUNNER_TOOL_CACHE
	) {
		if ($Require) {
			return Write-GitHubActionsFail -Message 'This process require to execute inside the GitHub Actions environment!'
		}
		return $false
	}
	return $true
}
Set-Alias -Name 'Test-GHActionsEnvironment' -Value 'Test-GitHubActionsEnvironment' -Option 'ReadOnly' -Scope 'Local'
Export-ModuleMember -Function @(
	'Add-GitHubActionsEnvironmentVariable',
	'Add-GitHubActionsPATH',
	'Add-GitHubActionsProblemMatcher',
	'Add-GitHubActionsSecretMask',
	'Add-GitHubActionsStepSummary',
	'Disable-GitHubActionsEchoingCommands',
	'Disable-GitHubActionsProcessingCommands',
	'Enable-GitHubActionsEchoingCommands',
	'Enable-GitHubActionsProcessingCommands',
	'Enter-GitHubActionsLogGroup',
	'Exit-GitHubActionsLogGroup',
	'Get-GitHubActionsInput',
	'Get-GitHubActionsIsDebug',
	'Get-GitHubActionsOidcToken,'
	'Get-GitHubActionsState',
	'Get-GitHubActionsStepSummary',
	'Get-GitHubActionsWebhookEventPayload',
	'Remove-GitHubActionsProblemMatcher',
	'Remove-GitHubActionsStepSummary',
	'Set-GitHubActionsOutput',
	'Set-GitHubActionsState',
	'Set-GitHubActionsStepSummary',
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
	'Add-GHActionsStepSummary',
	'Add-GitHubActionsEnv',
	'Add-GitHubActionsEnvironment',
	'Add-GitHubActionsMask',
	'Add-GitHubActionsSecret',
	'Disable-GHActionsCommandEcho',
	'Disable-GHActionsCommandEchoing',
	'Disable-GHActionsCommandProcess',
	'Disable-GHActionsCommandProcessing',
	'Disable-GHActionsCommandsEcho',
	'Disable-GHActionsCommandsEchoing',
	'Disable-GHActionsCommandsProcess',
	'Disable-GHActionsCommandsProcessing',
	'Disable-GHActionsEchoCommand',
	'Disable-GHActionsEchoCommands',
	'Disable-GHActionsEchoingCommand',
	'Disable-GHActionsEchoingCommands',
	'Disable-GHActionsProcessCommand',
	'Disable-GHActionsProcessCommands',
	'Disable-GHActionsProcessingCommand',
	'Disable-GHActionsProcessingCommands',
	'Disable-GitHubActionsCommandEcho',
	'Disable-GitHubActionsCommandEchoing',
	'Disable-GitHubActionsCommandProcess',
	'Disable-GitHubActionsCommandProcessing',
	'Disable-GitHubActionsCommandsEcho',
	'Disable-GitHubActionsCommandsEchoing',
	'Disable-GitHubActionsCommandsProcess',
	'Disable-GitHubActionsCommandsProcessing',
	'Disable-GitHubActionsEchoCommand',
	'Disable-GitHubActionsEchoCommands',
	'Disable-GitHubActionsEchoingCommand',
	'Disable-GitHubActionsProcessCommand',
	'Disable-GitHubActionsProcessCommands',
	'Disable-GitHubActionsProcessingCommand',
	'Enable-GHActionsCommandEcho',
	'Enable-GHActionsCommandEchoing',
	'Enable-GHActionsCommandProcess',
	'Enable-GHActionsCommandProcessing',
	'Enable-GHActionsCommandsEcho',
	'Enable-GHActionsCommandsEchoing',
	'Enable-GHActionsCommandsProcess',
	'Enable-GHActionsCommandsProcessing',
	'Enable-GHActionsEchoCommand',
	'Enable-GHActionsEchoCommands',
	'Enable-GHActionsEchoingCommand',
	'Enable-GHActionsEchoingCommands',
	'Enable-GHActionsProcessCommand',
	'Enable-GHActionsProcessCommands',
	'Enable-GHActionsProcessingCommand',
	'Enable-GHActionsProcessingCommands',
	'Enable-GitHubActionsCommandEcho',
	'Enable-GitHubActionsCommandEchoing',
	'Enable-GitHubActionsCommandProcess',
	'Enable-GitHubActionsCommandProcessing',
	'Enable-GitHubActionsCommandsEcho',
	'Enable-GitHubActionsCommandsEchoing',
	'Enable-GitHubActionsCommandsProcess',
	'Enable-GitHubActionsCommandsProcessing',
	'Enable-GitHubActionsEchoCommand',
	'Enable-GitHubActionsEchoCommands',
	'Enable-GitHubActionsEchoingCommand',
	'Enable-GitHubActionsProcessCommand',
	'Enable-GitHubActionsProcessCommands',
	'Enable-GitHubActionsProcessingCommand',
	'Enter-GHActionsGroup',
	'Enter-GHActionsLogGroup',
	'Enter-GitHubActionsGroup',
	'Exit-GHActionsGroup',
	'Exit-GHActionsLogGroup',
	'Exit-GitHubActionsGroup',
	'Get-GHActionsEvent',
	'Get-GHActionsInput',
	'Get-GHActionsIsDebug',
	'Get-GHActionsOidcToken',
	'Get-GHActionsPayload',
	'Get-GHActionsState',
	'Get-GHActionsStepSummary',
	'Get-GHActionsWebhookEvent',
	'Get-GHActionsWebhookEventPayload',
	'Get-GHActionsWebhookPayload',
	'Get-GitHubActionsEvent',
	'Get-GitHubActionsPayload',
	'Get-GitHubActionsWebhookEvent',
	'Get-GitHubActionsWebhookPayload',
	'Remove-GHActionsProblemMatcher',
	'Remove-GHActionsStepSummary',
	'Restore-GHActionsState',
	'Restore-GitHubActionsState',
	'Save-GHActionsState',
	'Save-GitHubActionsState',
	'Set-GHActionsOutput',
	'Set-GHActionsState',
	'Set-GHActionsStepSummary',
	'Start-GHActionsCommandEcho',
	'Start-GHActionsCommandEchoing',
	'Start-GHActionsCommandProcess',
	'Start-GHActionsCommandProcessing',
	'Start-GHActionsCommandsEcho',
	'Start-GHActionsCommandsEchoing',
	'Start-GHActionsCommandsProcess',
	'Start-GHActionsCommandsProcessing',
	'Start-GHActionsEchoCommand',
	'Start-GHActionsEchoCommands',
	'Start-GHActionsEchoingCommand',
	'Start-GHActionsEchoingCommands',
	'Start-GHActionsProcessCommand',
	'Start-GHActionsProcessCommands',
	'Start-GHActionsProcessingCommand',
	'Start-GHActionsProcessingCommands',
	'Start-GitHubActionsCommandEcho',
	'Start-GitHubActionsCommandEchoing',
	'Start-GitHubActionsCommandProcess',
	'Start-GitHubActionsCommandProcessing',
	'Start-GitHubActionsCommandsEcho',
	'Start-GitHubActionsCommandsEchoing',
	'Start-GitHubActionsCommandsProcess',
	'Start-GitHubActionsCommandsProcessing',
	'Start-GitHubActionsEchoCommand',
	'Start-GitHubActionsEchoCommands',
	'Start-GitHubActionsEchoingCommand',
	'Start-GitHubActionsEchoingCommands',
	'Start-GitHubActionsProcessCommand',
	'Start-GitHubActionsProcessCommands',
	'Start-GitHubActionsProcessingCommand',
	'Start-GitHubActionsProcessingCommands',
	'Stop-GHActionsCommandEcho',
	'Stop-GHActionsCommandEchoing',
	'Stop-GHActionsCommandProcess',
	'Stop-GHActionsCommandProcessing',
	'Stop-GHActionsCommandsEcho',
	'Stop-GHActionsCommandsEchoing',
	'Stop-GHActionsCommandsProcess',
	'Stop-GHActionsCommandsProcessing',
	'Stop-GHActionsEchoCommand',
	'Stop-GHActionsEchoCommands',
	'Stop-GHActionsEchoingCommand',
	'Stop-GHActionsEchoingCommands',
	'Stop-GHActionsProcessCommand',
	'Stop-GHActionsProcessCommands',
	'Stop-GHActionsProcessingCommand',
	'Stop-GHActionsProcessingCommands',
	'Stop-GitHubActionsCommandEcho',
	'Stop-GitHubActionsCommandEchoing',
	'Stop-GitHubActionsCommandProcess',
	'Stop-GitHubActionsCommandProcessing',
	'Stop-GitHubActionsCommandsEcho',
	'Stop-GitHubActionsCommandsEchoing',
	'Stop-GitHubActionsCommandsProcess',
	'Stop-GitHubActionsCommandsProcessing',
	'Stop-GitHubActionsEchoCommand',
	'Stop-GitHubActionsEchoCommands',
	'Stop-GitHubActionsEchoingCommand',
	'Stop-GitHubActionsEchoingCommands',
	'Stop-GitHubActionsProcessCommand',
	'Stop-GitHubActionsProcessCommands',
	'Stop-GitHubActionsProcessingCommand',
	'Stop-GitHubActionsProcessingCommands',
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
