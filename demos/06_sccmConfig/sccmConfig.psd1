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
            Role = 'SCCM'
            Features = @("Web-Windows-Auth","Web-ISAPI-Ext","Web-Metabase","Web-WMI","BITS","RDC","NET-Framework-Features","Web-Asp-Net","Web-Asp-Net45","NET-HTTP-Activation","NET-Non-HTTP-Activ","Web-Static-Content","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Http-Redirect","Web-App-Dev","Web-Net-Ext","Web-Net-Ext45","Web-ISAPI-Filter","Web-Health","Web-Http-Logging","Web-Log-Libraries","Web-Request-Monitor","Web-HTTP-Tracing","Web-Security","Web-Filtering","Web-Performance","Web-Stat-Compression","Web-Mgmt-Console","Web-Scripting-Tools","Web-Mgmt-Compat")
        }
    )
}