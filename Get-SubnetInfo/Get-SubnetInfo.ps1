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
