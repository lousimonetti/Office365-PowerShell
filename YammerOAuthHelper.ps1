[System.Reflection.Assembly]::LoadWithPartialName("System.Web")
$SleepInterval = 1

Function Get-Code()
{
[OutputType([string])]
  param ($urlEndPoint)
  $IE = New-Object -ComObject InternetExplorer.Application;
  $IE.Navigate($urlEndPoint);
  $IE.Visible = $true;

  while ($IE.LocationUrl -notmatch "code") {
      Write-host  ‘Sleeping {0} seconds for access URL’ -f $SleepInterval;
      Start-Sleep -Seconds $SleepInterval;
  }

  [string]$fyi = (($IE.LocationUrl  -split ',*code=')[1]);
  
  $IE.Quit();

  return $fyi;
}


function Get-YammerToken() 
{
  #setup the client connection
  $clientId = "<REPLACE WITH YOUR YAMMER APP CLIENT ID>"
  $clientSecret ="<REPLACE WITH YOUR YAMMER APP CLIENT SECRET>"
  $rdurl = "<REPLACE WITH YOUR YAMMER APP REDIRECT URL>"
    
  $redirectUrl = [System.Web.HttpUtility]::UrlEncode($rdurl) 
  $yammer= "https://www.yammer.com/oauth2/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUrl"
  $tempCode = [string](Get-Code -urlEndPoint $yammer)
  $tempCode = $tempCode.Replace(" ", "")
  $yammerLeg2 = "https://www.yammer.com/oauth2/access_token.json?client_id=$clientId&client_secret=$clientSecret&code=$tempCode"
  $r = Invoke-WebRequest $yammerLeg2 -Method Get | ConvertFrom-Json
  $accessToken = $r.access_token
  return $accessToken.token;
}

#Function to add user to a Group 
Function Set-YammerGroups()
{
  Param ($token, $userId, $groupId, $email) 
  
  #configure the Headers for the REST API call
  
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization", 'Bearer '+ $token)
  $headers.Add("accept-encoding", "gzip, deflate")
  $headers.Add("content-type", "application/json")

  #Configure the JSON Object for the push
  $body = New-Object PSObject
  Add-Member -MemberType NoteProperty -Name group_id -Value $groupId -InputObject $body
  Add-Member -MemberType NoteProperty -Name user_id -Value $userId -InputObject $body
  Add-Member -MemberType NoteProperty -Name email -Value $email -InputObject $body
  $jsonBody =$body|ConvertTo-Json
  
  #the API URL
  $groupUrl = "https://www.yammer.com/api/v1/group_memberships.json"

  #invoke the call 
  $answer =Invoke-RestMethod $groupUrl -Headers $headers -Method Post -Body $jsonBody
}

$Global:yammerToken  = Get-YammerToken();
