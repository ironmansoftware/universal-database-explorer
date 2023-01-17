Import-Module dbatools

New-UDDashboard -Title 'PowerShell Universal' -Pages @(
    New-UDPage -Name 'Home' -Content {
        
        $Session:Server = '(localdb)\MSSQLLocalDB'
        if (-not $Session:Server) {
            $Session:Server = Read-Host "SQL Instance"
            Sync-UDElement -Id 'content'
        }
        
        New-UDDynamic -Id 'content' -Content {
            if (-not $Session:Server) {
                return
            }

            New-UDButton -Text 'Set SQL Instance' -OnClick {
                $Session:Server = Read-Host "SQL Instance"
                Sync-UDElement -Id 'content'
            } -Icon (New-UDIcon -Icon 'Plug')

            $Databases = Get-DbaDatabase -SqlInstance $Session:Server | Select-Object Name, SizeMB
            New-UDTable -Data $Databases -Columns @(
                New-UDTableColumn -Property 'Name' -Title 'Name' 
                New-UDTableColumn -Property 'SizeMB' -Title 'Size (MB)'
                New-UDTableColumn -Property 'Actions' -Title 'Actions' -Render {
                    New-UDButton -Text 'View' -OnClick {
                        Invoke-UDRedirect -Url "/database/$($EventData.Name)"
                    }
                }
            ) -Dense -Title 'Databases' -Icon (New-UDIcon -Icon 'Database')
        }
    }
    New-UDPage -Name 'Table' -Url "/database/:database/table/:table" -Content {
        $Data = Invoke-DbaQuery -Database $Database -SqlInstance $Session:Server -Query "SELECT * FROM $Table"
        $Columns = $Data | Get-Member -MemberType Property | ForEach-Object {
            New-UDTableColumn -Property $_.Name 
        }
        New-UDTable -Data $Data -Columns $Columns -Dense -Title "$Database - $Table" -Icon (New-UDIcon -Icon 'Table') -ShowPagination
    }
    New-UDPage -Name 'Database' -Url "/database/:database" -Content {
        $Tables = Get-DbaDbTable -SqlInstance $Session:Server -Database $Database | Select-Object Name
        New-UDTable -Data $Tables -Columns @(
            New-UDTableColumn -Property 'Name' -Title 'Name' 
            New-UDTableColumn -Property 'Actions' -Title 'Actions' -Render {
                New-UDButton -Text 'View' -OnClick {
                    Invoke-UDRedirect -Url "/database/$Database/table/$($EventData.Name)"
                }
            }
        ) -Dense -Title "$Database - Tables" -Icon (New-UDIcon -Icon 'Table') -ShowPagination

        $Users = Get-DbaDbUser -SqlInstance $Session:Server -Database $Database

        New-UDTable -Data $Users -Columns @(
            New-UDTableColumn -Property 'Name' -Title 'Name' 
        ) -Dense -Title "$Database - Users" -Icon (New-UDIcon -Icon 'User') -ShowPagination

        New-UDDynamic -Content {
            $Views = Get-DbaDbView -SqlInstance $Session:Server -Database $Database

            New-UDTable -Data $Views -Columns @(
                New-UDTableColumn -Property 'Name' -Title 'Name' 
            ) -Dense -Title "$Database - Views" -Icon (New-UDIcon -Icon 'Eye') -ShowPagination
        }

    }

)