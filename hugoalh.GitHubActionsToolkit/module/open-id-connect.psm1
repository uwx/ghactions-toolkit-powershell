#Requires -PSEdition Core
#Requires -Version 7.2
Import-Module -Name @(
	(Join-Path -Path $PSScriptRoot -ChildPath 'utility.psm1')
) -Prefix 'GitHubActions' -Scope 'Local'
<#
.SYNOPSIS
GitHub Actions - Get OpenID Connect Token
.DESCRIPTION
Interact with the GitHub OpenID Connect (OIDC) provider and get a JSON Web Token (JWT) ID token which would help to get access token from third party cloud providers.
.PARAMETER Audience
Audience.
.OUTPUTS
String
#>
function Get-OpenIdConnectToken {
	[CmdletBinding(HelpUri = 'https://github.com/hugoalh-studio/ghactions-toolkit-powershell/wiki/api_function_get-githubactionsopenidconnecttoken#Get-GitHubActionsOpenIdConnectToken')]
	[OutputType([String])]
	param (
		[Parameter(Position = 0)][String]$Audience
	)
	[String]$OidcTokenRequestToken = $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN
	[String]$OidcTokenRequestURL = $env:ACTIONS_ID_TOKEN_REQUEST_URL
	if ($OidcTokenRequestToken.Length -ieq 0) {
		return Write-Error -Message 'Unable to get GitHub Actions OIDC token request token!' -Category 'ResourceUnavailable'
	}
	Add-GitHubActionsSecretMask -Value $OidcTokenRequestToken
	if ($OidcTokenRequestURL.Length -ieq 0) {
		return Write-Error -Message 'Unable to get GitHub Actions OIDC token request URL!' -Category 'ResourceUnavailable'
	}
	if ($Audience.Length -igt 0) {
		Add-GitHubActionsSecretMask -Value $Audience
		[String]$AudienceEncode = [System.Web.HttpUtility]::UrlEncode($Audience)
		Add-GitHubActionsSecretMask -Value $AudienceEncode
		$OidcTokenRequestURL += "&audience=$AudienceEncode"
	}
	try {
		[PSCustomObject]$Response = Invoke-WebRequest -Uri $OidcTokenRequestURL -UseBasicParsing -UserAgent 'actions/oidc-client' -Headers @{
			Authorization = "Bearer $OidcTokenRequestToken"
		} -MaximumRedirection 1 -MaximumRetryCount 10 -RetryIntervalSec 10 -Method 'Get'
		[ValidateNotNullOrEmpty()][String]$OidcToken = (ConvertFrom-Json -InputObject $Response.Content -Depth 100).value
		Add-GitHubActionsSecretMask -Value $OidcToken
		return $OidcToken
	} catch {
		return Write-Error @_
	}
}
Set-Alias -Name 'Get-OidcToken' -Value 'Get-OpenIdConnectToken' -Option 'ReadOnly' -Scope 'Local'
Export-ModuleMember -Function @(
	'Get-OpenIdConnectToken'
) -Alias @(
	'Get-OidcToken'
)