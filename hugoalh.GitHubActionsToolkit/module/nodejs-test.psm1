#Requires -PSEdition Core
#Requires -Version 7.2
[Boolean]$EnvironmentResult = $False
[Boolean]$EnvironmentTested = $False
[SemVer]$NodeJsMinimumVersion = [SemVer]::Parse('14.15.0')
[SemVer]$NpmMinimumVersion = [SemVer]::Parse('6.14.8')
[RegEx]$SemVerRegEx = '^v?\d+\.\d+\.\d+$'
[String]$WrapperRoot = Join-Path -Path $PSScriptRoot -ChildPath 'nodejs-wrapper'
<#
.SYNOPSIS
GitHub Actions - Test NodeJS Environment
.DESCRIPTION
Test the current machine whether has compatible NodeJS and NPM environment, and has dependencies ready; Test result always cache for reuse.
.PARAMETER ReinstallDependencies
Whether to force reinstall dependencies even though available.
.PARAMETER Retest
Whether to redo this test, ignore the cached test result.
.OUTPUTS
[Boolean] Test result.
#>
Function Test-NodeJsEnvironment {
	[CmdletBinding()]
	[OutputType([Boolean])]
	Param (
		[Alias('Reinstall', 'ReinstallDependency', 'ReinstallPackage', 'ReinstallPackages')][Switch]$ReinstallDependencies,
		[Alias('Redo')][Switch]$Retest
	)
	If ($EnvironmentTested -and !$ReinstallDependencies.IsPresent -and !$Retest.IsPresent) {
		Write-Verbose -Message 'Previously tested NodeJS environment; Return previous result.'
		Write-Output -InputObject $EnvironmentResult
		Return
	}
	$Script:EnvironmentTested = $False
	Try {
		Write-Verbose -Message 'Test NodeJS.'
		Get-Command -Name 'node' -CommandType 'Application' -ErrorAction 'Stop' |# `Get-Command` will throw error when nothing is found.
			Out-Null# No need the result.
		[String]$ExpressionNodeJsVersionResult = node --no-deprecation --no-warnings --version |
			Join-String -Separator "`n"
		If (
			$ExpressionNodeJsVersionResult -inotmatch $SemVerRegEx -or
			$NodeJsMinimumVersion -igt [SemVer]::Parse(($ExpressionNodeJsVersionResult -ireplace '^v', ''))
		) {
			Throw
		}
		Write-Verbose -Message 'Test NPM.'
		Get-Command -Name 'npm' -CommandType 'Application' -ErrorAction 'Stop' |# `Get-Command` will throw error when nothing is found.
			Out-Null# No need the result.
		[String]$ExpressionNpmVersionResult = npm --version |
			Join-String -Separator "`n"
		If (
			$ExpressionNpmVersionResult -inotmatch $SemVerRegEx -or
			$NpmMinimumVersion -igt [SemVer]::Parse(($ExpressionNpmVersionResult -ireplace '^v', ''))
		) {
			Throw
		}
	}
	Catch {
		$Script:EnvironmentTested = $True
		$Script:EnvironmentResult = $False
		Write-Output -InputObject $EnvironmentResult
		Return
	}
	$OriginalWorkingDirectory = Get-Location
	Write-Verbose -Message 'Test NodeJS wrapper API dependencies.'
	Set-Location -LiteralPath $WrapperRoot
	Try {
		If (
			$ReinstallDependencies.IsPresent -or
			(
				npm outdated |
					Join-String -Separator "`n"
			) -cmatch 'MISSING'
		) {
			Write-Verbose -Message 'Install/Reinstall NodeJS wrapper API dependencies.'
			npm ci --ignore-scripts --no-audit --no-fund |
				Out-Null# No need the result.
			If ($LASTEXITCODE -ine 0) {
				Throw
			}
		}
	}
	Catch {
		Set-Location -LiteralPath $OriginalWorkingDirectory
		$Script:EnvironmentTested = $True
		$Script:EnvironmentResult = $False
		Write-Output -InputObject $EnvironmentResult
		Return
	}
	Set-Location -LiteralPath $OriginalWorkingDirectory
	$Script:EnvironmentTested = $True
	$Script:EnvironmentResult = $True
	Write-Output -InputObject $EnvironmentResult
}
Export-ModuleMember -Function @(
	'Test-NodeJsEnvironment'
)
