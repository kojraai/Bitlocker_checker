# VARS
$drives = @(Get-WmiObject win32_logicaldisk| ?{$_.drivetype -eq 3} | foreach-object {$_.name} | out-string)
$username = [Environment]::UserName
$machine_name = $env:COMPUTERNAME
$btlck_drive = Get-BitLockerVolume | select-object -expandproperty mountpoint 
$btlck_ison = Get-BitLockerVolume | select-object -expandproperty Protectionstatus 
$output = "${username}_$ison.json"
$capacity = Get-BitLockerVolume | select-object -expandproperty capacityGB 
$On = "on"
$items = @()

## Check bitlocker status on all drives (If there are any drives without status ON then set $ison = Off), this means all drives must have bitlocker enabled
ForEach($drive in $btlck_ison)
{
   if ($drive -eq $On){
           $On_counter = $drive.COunt
   }
   else{
           $Off_counter = $drive.COunt
   }
        if ($Off_counter -ge $On_counter){
		
                $ison = "Off"
		}
        else {
                $ison = "On"
		}
}

### Check machine type (Laptop or Desktop)
function Get-HardwareType {

    $hardwaretype = Get-WmiObject -Class Win32_ComputerSystem -Property PCSystemType |
	Select-Object -ExpandProperty PCSystemType
        If ($hardwaretype -ne 2)
        {
		return $true
        }
        Else
        {
        return $false
		$pc = "pc"
        }
}
	If (Get-HardwareType)
		{
			$hwtype = "Desktop"
		}
	Else
		{
			$hwtype = "Laptop"
		}

#### Get bitlocker info and add custom field "isRecovery" for drives that less than 10 GB
foreach($recovery_drive in $btlck_drive){

$capacity = Get-BitLockerVolume $recovery_drive | select-object -expandproperty capacityGB
$int_capacity = [int]$capacity
$recovery_drive_limit = 10

     if ([int]$int_capacity -le $recovery_drive_limit){

					$isrecovery = "True"   
				$btlck_data = Get-BitLockerVolume $recovery_drive | select  mountpoint, volumestatus, volumetype, CapacityGB, protectionstatus 	
				$btlck_data | Add-Member -type NoteProperty -Name 'isRecovery' -Value $isrecovery
                                
    }
    else{

					$isrecovery = "False"                 
				$btlck_data = Get-BitLockerVolume $recovery_drive | select  mountpoint, volumestatus, volumetype, CapacityGB, protectionstatus
				$btlck_data | Add-Member -type NoteProperty -Name 'isRecovery' -Value $isrecovery
    }
    
    $items += $btlck_data
}   

############# Convert and write output	  
   $Object = New-Object PSObject -Property @{            

		
        drives           = $items              
		userName         = $username 
		type			 = $hwtype
		MachineName		 = $machine_name
	
                
    }     
$output2 = "\\share\${username}_$ison.json"
$Object | ConvertTo-Json > $output2

	
