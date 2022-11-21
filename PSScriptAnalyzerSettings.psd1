@{
    'Rules'        = @{
        PSAvoidUsingCmdletAliases        = @{
            'allowlist' = @('git')
        }
        PSAvoidUsingPositionalParameters = @{
            CommandAllowList = 'az', 'Join-Path'
            Enable           = $true
        }
    }
    'ExcludeRules' = @('PSAvoidUsingWriteHost')
}
