@{
    'Rules'        = @{
        'PSAvoidUsingCmdletAliases' = @{
            'allowlist' = @('git')
        }
    }
    'ExcludeRules' = @('PSAvoidUsingWriteHost')
}
