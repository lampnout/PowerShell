# Original script by Parvez Anwar (@parvezghh)

#powershell.exe -executionpolicy bypass -file permchk.ps1

$file = "tmpfile.txt"

# environmetal path to array (arpath)
$arpath = $env:path.split(';')

Write-Host "Number of paths to check: " $arpath.count
New-Item $file -type file | Out-Null

for($i=0; $i -le $arpath.count-1; $i++)
{
	# path exists
	if (Test-Path -path $arpath[$i])
	{
		Copy-Item $file $arpath[$i] -errorAction SilentlyContinue -errorVariable errors
		
		# successful copy
		if ($errors.count -le 0)
		{
			Write-Host " [+] Writable path:" $arpath[$i]
			$removefile = $arpath[$i]+"\"+$file
            Remove-Item $removefile
		}
		# unsuccessful copy
		else
		{
			Write-Host " [-] Not writable path:" $arpath[$i] 
		}
	}
	else
	{
		Write-Host " [*] Folder is missing:" $arpath[$i]
	}
}
Remove-Item $file
