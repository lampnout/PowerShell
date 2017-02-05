Function Scan-ARP2 {
	
	Param(
		[string]$ipcidr
	)
	
	$signature=@"
	[DllImport("iphlpapi.dll", ExactSpelling=true)]
	public static extern int SendARP( int destIp, int srcIP, byte[] macAddr, ref uint physicalAddrLen );
"@

	$sendarp = Add-Type -memberDefinition $signature -name "Win32SendARP" -namespace Win32Functions -passThru

	# split IP and SubnetMask
	$spl = $ipcidr -split '\/'
	
	if ( $spl[1] ) {

		# cidr (ip+subnetmask)

		$lowlimit = Convert-IPToUInt $($(Get-SubnetInfo $ipcidr).network)
		$upperlimit = Convert-IPToUInt $($(Get-SubnetInfo $ipcidr).broadcast)
		
		[uint64]$dif = $upperlimit - $lowlimit
		[int]$count = 0
		
		# lowlimit has the network address
		for ($i=1; $i -lt $dif; $i++) {
			$temp = 168430179 + $i

			$macAddr = New-Object byte[] 6
			$macLen = $macAddr.Length
			
			$ip = [Net.IPAddress]::Parse($(Convert-UIntToIP $temp))
				
			if ($sendarp::SendARP([BitConverter]::ToInt32($ip.GetAddressBytes(), 0), 0, $macAddr, [ref]$macLen) -eq 0) {
				$macA = ($macAddr | Foreach {"{0:X2}" -f $_}) -join ":"
				Write-Host $ip"    "$macA
				$count++
			}
			#else {
				#Write-Host "No host for ip "$ip
			#}
		}
		Write-Host $count " packets received"
	}
	else {

		# ip only

		$macAddr = New-Object byte[] 6
		$macLen = $macAddr.length

		$ip = [Net.IPAddress]::Parse($($spl[0]))
						
		if ($sendarp::SendARP([BitConverter]::ToInt32($ip.GetAddressBytes(), 0), 0, $macAddr, [ref]$macLen) -eq 0) {
				$macA = ($macAddr | Foreach {"{0:X2}" -f $_}) -join ":"
				Write-Host $i"    "$ip"    "$macA
		}
		else {
				Write-Host "No host for "$ip
		}
	}
}

Function Convert-UIntToIP {

	# converts uint to ip. example: 3232235777 -> 192.168.1.1
	Param(
		[uint64]$number
	)

	[string]$ip = Convert-BinStrToIP $(Convert-UIntToBinStr $number)
	
	return $ip
	
}

Function Convert-IPToUInt {
	
	# converts ip to uint. example: 192.168.1.1 -> 3232235777
	Param(
		[string]$ip
	)
	
	[uint64]$number = Convert-BinStrToUInt $(Convert-IPToBinStr $ip)
	
	return $number
	
}

Function Convert-UIntToBinStr {

	# converts uint to 32-bit binary string. example: 3232235777 -> 11000000101010000000000100000001
	Param(
		[uint64]$number
	)
	
	[string]$str = $([convert]::tostring($number,2)).padleft(32,'0')
	
	return $str
	
}

Function Convert-BinStrToUInt {

	# converts 32-bit binary string to uint. example: 11000000101010000000000100000001 -> 3232235777
	Param(
		[string]$str
	)
	
	[uint64]$number = [convert]::touint64($str,2)
	
	return $number
	
}

Function Convert-BinStrToIP {
	
	# converts 32-bit binary string to ip. example: 11000000101010000000000100000001 -> 192.168.1.1
	Param(
		[string]$binip
	)
	
	[string]$ip = $($($binip -replace '(........(?!$))','$1.') -split '\.' | foreach-object {[convert]::tobyte($_,2)}) -join '.'
	
	return $ip
	
}

Function Convert-IPToBinStr {
	
	# converts ip to 32-bit binary string. example: 192.168.1.1 -> 11000000101010000000000100000001
	Param(
		[string]$ip
	)
	
	[string]$binip = $($ip -split '\.' | foreach-object {[convert]::tostring($_,2).padleft(8,'0')}) -join ''
	
	return $binip
	
}

Function Get-SubnetInfo {
	<#
		.SYNOPSIS
			Displays information concerning a given subnet
			
		.DESCRIPTION
			The Get-SubnetInfo cmdlet gets a CIDR (Classless Inter-Domain Routing) IP address
			and lets you retrieve information about that range
			
			It calculates the resulting Broadcast, Network, Netmask and Network range (HostMin and HostMax)
			
		.EXAMPLE
			Get-SubnetInfo "192.168.1.180/26"
			
			HostMin    : 192.168.1.129
			Network    : 192.168.1.128
			Broadcast  : 192.168.1.191
			SubnetMask : 255.255.255.1
			HostMax    : 192.168.1.190
			
		.EXAMPLE
			Get-SubnetInfo "10.10.10.100/17"
			
			HostMin    : 10.10.0.1
			Network    : 10.10.0.0
			Broadcast  : 10.10.127.255
			SubnetMask : 255.255.128.0
			HostMax    : 10.10.127.254
			
		.LINK
			https://github.com/lampnout/PowerShell
	
	#>
	
	Param(
		[string]$cidr
	)
	
	if ($cidr) {
		$spl = $cidr -split '\/'
		$ip = $spl[0] -split '\.' | foreach-object {[convert]::tostring($_,2).padleft(8,'0')}
		$binip = $ip -join ''
	
		if ($spl[1]) {
		
			$binmask = ''.padleft($spl[1],'1')
			$ones = [regex]::matches($binmask,'1').count
			$zeros = 32 - $ones
							
			$binnetwork = $binip.substring(0,$ones) + ''.padleft($zeros,'0')
			$binbroadcast = $binip.substring(0,$ones) + ''.padleft($zeros,'1')
			$binmask = $binmask + ''.padleft($zeros,'0')
			$binhostmin = $binip.substring(0,$ones) + ''.padleft($zeros-1,'0') + ''.padleft(1,'1')
			$binhostmax = $binip.substring(0,$ones) + ''.padleft($zeros-1,'1') + ''.padleft(1,'0')
			
			$network = $($($binnetwork -replace '(........(?!$))','$1.') -split '\.' | foreach-object {[convert]::tobyte($_,2)}) -join '.'
			$broadcast = $($($binbroadcast -replace '(........(?!$))','$1.') -split '\.' | foreach-object {[convert]::tobyte($_,2)}) -join '.'
			$hostmin = $($($binhostmin -replace '(........(?!$))','$1.') -split '\.' | foreach-object {[convert]::tobyte($_,2)}) -join '.'
			$hostmax = $($($binhostmax -replace '(........(?!$))','$1.') -split '\.' | foreach-object {[convert]::tobyte($_,2)}) -join '.'
			$subnetmask = $($($binmask -replace '(........(?!$))','$1.') -split '\.' | foreach-object {[convert]::tobyte($_,2)}) -join '.'
			
			$properties = @{'HostMin'=$hostmin;
							'HostMax'=$hostmax;
							'SubnetMask'=$subnetmask;
							'Broadcast'=$broadcast;
							'Network'=$network;
							}
			
			$object = New-Object -TypeName PSObject -Property $properties
			
			return $object
		
		}
	}
}
