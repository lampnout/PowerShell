# powershell -executionpolicy bypass -file hostdisc.ps1

$localip = (Test-Connection -ComputerName (hostname) -count 1).ipv4address.ipaddresstostring    # current ip address
$netmask = Get-wmiobject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -match $localip} | Select-Object -expand IPSubnet   # current netmask
$del = "."

$netmask = $netmask.split($del)
$localip = $localip.split($del)

$netmaskbin = [convert]::tostring($netmask[0],2)+[convert]::tostring($netmask[1],2)+[convert]::tostring($netmask[2],2)+[convert]::tostring($netmask[3],2)
$ones = ([regex]::matches($netmaskbin,"1")).count
$zeros = 32-$ones

if ( $ones -lt 24)
{
    Write-Host 'This script does not support host disovery for < /24 subnets'
    break
}

$localipbin=''
for($i=0; $i -le 3; $i++)
{
    $temp = [convert]::tostring($localip[$i],2)
    if ($temp.length -ne 8)
    {
        $temp = ''.padleft(8-$temp.length,'0')+$temp
    }
    $localipbin= $localipbin+$temp
}

$localipbin = $localipbin.substring(0, $ones) + ''.padleft($zeros, '0')
$lastnetip = $localipbin.substring(0, $ones) + ''.padleft($zeros, '1')

$netip = ''

for($i=0; $i -le 3; $i++)
{
    $temp = [convert]::toint32($localipbin.substring($i*8,8),2)
    if ($i -lt 3) 
    {
        $temp = $temp.tostring()+'.'
        $netip = $netip+$temp
    }
    else
    {
        $start = $temp
    }
}

$end = [convert]::toint32($lastnetip.substring(24,8),2)     # last ip to ping

for($i=$start; $i -le $end; $i++)
{
	if (Test-Connection -Computername $netip$i -count 1 -quiet)
	{
		Write-Host " [+] Host:" $netip$i " is up"
	}
}
