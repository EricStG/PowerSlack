[string] $script:Slacktoken = "";
[string] $slackUri = "https://slack.com/api"


# Inspired from https://gist.github.com/rdsimes/4333461
function ConvertTo-UnixTimestamp {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[DateTime] $date
	)
	$epoch = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0	
	[math]::truncate($date.ToUniversalTime().Subtract($epoch).TotalSeconds)
}

function Validate-Token{
	[CmdletBinding()]
	param ()
	if ([string]::IsNullOrEmpty($script:Slacktoken))
	{
		throw "Token cannot be empty. Use Set-SlackToken before any call."
	}
}


function Set-SlackToken {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $token
	)
	Write-Verbose "Setting Slack token to $token"
	$script:SlackToken = $token
}

function Get-SlackChannels {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[switch] $excludeArchived = $false
	)
	Validate-Token
	$uri = "$slackUri/channels.list"
	
	$params =  @{"token" = $script:Slacktoken}
	
	if ($excludeArchived) {
		$params.Set_Item("exclude_archived", "1")
	}
	
	$result = Invoke-RestMethod -Method "Get" -Uri $uri -ContentType "Application/Json" -body $params
	
	if ($result.ok -eq "true") {
		Write-Verbose "Response is good"
		foreach ($message in $result.channels) {
			$message
		}
	}
	
	#todo : error handling

}

function Get-SlackChannelHistory {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $channel,
		[Parameter(Mandatory = $false)]
		[Nullable[DateTime]] $latest = $null,
		[Parameter(Mandatory = $false)]
		[Nullable[DateTime]] $oldest = $null,
		[Parameter(Mandatory = $false)]
		[switch] $inclusive = $true,
		[ValidateRange(1,1000)] 
		[Parameter(Mandatory = $false)]
		[Nullable[int]] $count = $null,
		[Parameter(Mandatory = $false)]
		[switch] $unread = $false
	)
	Validate-Token
	$uri = "$slackUri/channels.history"
	
	$params =  @{"token" = $script:Slacktoken; "channel" = $channel}
	
	if ($latest) {
		$val = ConvertTo-UnixTimestamp $latest
		Write-Verbose "Setting latest parameter to $val"
		$params.Set_Item("latest", $val)
		
	}
	
	if ($oldest) {
		$val = ConvertTo-UnixTimestamp $oldest
		Write-Verbose "Setting oldest parameter to $val"
		$params.Set_Item("oldest", $val)
	}
	
	if ($inclusive) {
		$params.Set_Item("inclusive", 1)
	}
	
	if ($count) {
		$params.Set_Item("count", $count)
	}
	
	if ($unread) {
		$params.Set_Item("unread", 1)
	}
	
	$result = Invoke-RestMethod -Method "Get" -Uri $uri -ContentType "Application/Json" -body $params
	
	if ($result.ok -eq "true") {
		Write-Verbose "Response is good"
		foreach ($message in $result.messages) {
			$message
		}
	}
	
	#todo : error handling
}

function Delete-SlackMessage {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $channel,
		[Parameter(Mandatory = $true)]
		[string] $ts
	)

	Validate-Token
	$uri = "$slackUri/chat.delete"
	
	$params =  @{"token" = $script:Slacktoken; "channel" = $channel; "ts" = $ts}
	
	Invoke-RestMethod -Method "Get" -Uri $uri -ContentType "Application/Json" -body $params
}





Export-ModuleMember -Function Get-SlackChannelHistory
Export-ModuleMember -Function Set-SlackToken
Export-ModuleMember -Function Get-SlackChannels
Export-ModuleMember -Function Delete-SlackMessage