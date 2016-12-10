# powershell -executionpolicy bypass -file lastpatchk.ps1

$last = (Get-hotfix | Sort-Object InstalledOn)[-1] | Select-Object -ExpandProperty InstalledOn
$current = [datetime]::now

if ((New-TimeSpan -Start $last -End $current).Days -gt 35)
{
    Write-Host ' [+] System seems to be unpatched'
}
else
{
    Write-Host ' [-] System seems to be patched'
}
break
