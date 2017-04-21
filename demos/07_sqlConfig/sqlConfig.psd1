@{
    AllNodes = @(
        @{
            NodeName = '*';
            DomainName = 'corp.lab';
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser = $true;
        }
        @{
            NodeName = 'localhost'
            Role = 'SQL'
        }
    )
}