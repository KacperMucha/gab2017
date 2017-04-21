function Send-SlackMessage {
    [CmdletBinding()]
    param (
        [string]$Message
    )

    $webhook = 'https://hooks.slack.com/services/hook/url/id'
    $body = 'payload={"text": "' + $Message + '"}'
    Invoke-WebRequest -Uri $webhook -Method Post -Body $body
}