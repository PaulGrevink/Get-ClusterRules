# Get-ClusterRules.ps1
#
# Goal: The VMware PowerCLI Get-DrsRule cmdlet creates an overview of the configured DRS rules.
# Get-DrsRule distinguishes 3 ruletypes; VM to Host Affinity, VM VM Affinity and VM VM anti Affinity.
#
# For each Cluster in a vCenter Server, this script:
# 1. Creates a dump of the configured DRS rules,
# 2. Check the configured DRS rules against the actual situation (e.g. Is a VM to Host Affinity
#    "should" rule enforced or not?).
# 3. The status of rules (not)enabled and the power state of VMs is also shown. 
#
# Before running this script do the following:
# 1. Configure the variable $OutFile
# 2. Connect to a vCenter Server, using the Connect-VIServer cmdlet
#
# This script still needs improvements.


# Declare Variables and connect to vCenter Server
$vCenter="vcsa.virtual.local"
$user="administrator@vsphere.local"

Connect-VIServer -Server $vCenter -User $user 

# To show all output, see: https://greiginsydney.com/viewing-truncated-powershell-output/
$FormatEnumerationLimit=-1
Write-Host " "

# Get the Clusters
$clusters=Get-Cluster
for ($c=0; $c -lt $clusters.Count; $c++) {
    $cluster=$clusters[$c].Name
    # Change $OutFile to your needs.
    $OutFile="D:\Users\Paul\Documents\TRAINING\WindowsPowerShell\"+$cluster+".txt"
    
    Write-Host "=========================================================================================================================="
    Write-Host "Cluster name:" $cluster
    Write-Host "=========================================================================================================================="
    
    # Type VMHostAffinity VM run on these hosts (host affinity) or do not run on these hosts (hosyt anti affinity)
    $output=Get-DrsRule -Cluster $cluster -Type VMHostAffinity | Select-Object Cluster,Name,Type,Mandatory,Enabled, @{N="VMnames";E={ $_.Vmids|%{(get-view -id $_).name}}}, @{N="PowerState";E={ $_.Vmids|%{(get-view -id $_).Runtime.PowerState}}}, @{N="HostsWithAffinity";E={ $_.AffineHostIds|%{(get-view -id $_).name}}}, @{N="HostsWithAntiAffinity";E={ $_.AntiAffineHostIds|%{(get-view -id $_).name}}}
    $output > $OutFile

    #Number of rules in Cluster for this type is equal to: $output.Cluster.Count
    for ($i=0; $i -lt $output.Cluster.Count; $i++) {
        Write-Host "Rule name   :" $output[$i].Name

        #rule enabled
        if ( $output[$i].Enabled -eq "True" ) {
            Write-Host "Rule Enabled: Yes."
        }
        else {
            Write-Host "Rule Enabled: No. So don't worry about the next lines for now."
        }
   
        # VMs Must run on these hosts, mandatory is True
        if ( $output[$i].HostsWithAffinity.count -gt 0 -And $output[$i].Mandatory -eq "True") {
            Write-Host "Type        : Virtual Machines MUST run on these hosts"
            #Number of VMs is equal to: $output[$i].VMnames.Count
            for ($j=0; $j -lt $output[$i].VMnames.Count; $j++) {
                $realhost = Get-VM -Name $output[$i].VMnames[$j] | Select-Object VMHost
                if ( $output[$i].HostsWithAffinity -contains $realhost.VMHost.Name ) {
                    Write-Host "OK,      VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "must be placed on one of these hosts " $output[$i].HostsWithAffinity "and is placed on host " $realhost.VMHost.Name
                } 
                else {
                    Write-Host "ERROR,   VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "must be placed on one of these hosts " $output[$i].HostsWithAffinity " BUT is placed on host " $realhost.VMHost.Name
                }
            }
        }

        # VMs Should run on these hosts, mandatory is NOT True
        elseif ( $output[$i].HostsWithAffinity.count -gt 0 -And $output[$i].Mandatory -ne "True") {
            Write-Host "Type        : Virtual Machines Should run on these hosts"
            for ($j=0; $j -lt $output[$i].VMnames.Count; $j++) {
                $realhost = Get-VM -Name $output[$i].VMnames[$j] | Select-Object VMHost
                if ( $output[$i].HostsWithAffinity -contains $realhost.VMHost.Name ) {
                    Write-Host "OK,      VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "should be placed on one of these hosts " $output[$i].HostsWithAffinity " and is placed on host " $realhost.VMHost.Name
                } 
                else {
                    Write-Host "Warning, VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "should be placed on one of these hosts " $output[$i].HostsWithAffinity " BUT is placed on host " $realhost.VMHost.Name
                }
            }
        }

        # VMs Must NOT run on these hosts, mandatory is True
        elseif ( $output[$i].HostsWithAntiAffinity.count -gt 0 -And $output[$i].Mandatory -eq "True") {
            Write-Host "Type        : Virtual Machines MUST NOT run on these hosts"
            for ($j=0; $j -lt $output[$i].VMnames.Count; $j++) {
                $realhost = Get-VM -Name $output[$i].VMnames[$j] | Select-Object VMHost
                if ( $output[$i].HostsWithAntiAffinity -contains $realhost.VMHost.Name ) {
                    Write-Host "ERROR,   VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "must NOT be placed on one of these hosts " $output[$i].HostsWithAntiAffinity " BUT is placed on host " $realhost.VMHost.Name
                } 
                else {
                    Write-Host "OK,      VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "must NOT be placed on one of these hosts " $output[$i].HostsWithAntiAffinity " and is placed on host " $realhost.VMHost.Name
                }
            }
        }

        # VMs should NOT run on these hosts, mandatory is True
        elseif ( $output[$i].HostsWithAntiAffinity.count -gt 0 -And $output[$i].Mandatory -ne "True") {
            Write-Host "Type        : Virtual Machines MUST NOT run on these hosts"
            for ($j=0; $j -lt $output[$i].VMnames.Count; $j++) {
                $realhost = Get-VM -Name $output[$i].VMnames[$j] | Select-Object VMHost
                if ( $output[$i].HostsWithAntiAffinity -contains $realhost.VMHost.Name ) {
                    Write-Host "ERROR,   VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "should NOT be placed on one of these hosts " $output[$i].HostsWithAntiAffinity " BUT is placed on host " $realhost.VMHost.Name
                } 
                else {
                    Write-Host "OK,      VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "should NOT be placed on one of these hosts " $output[$i].HostsWithAntiAffinity " and is placed on host " $realhost.VMHost.Name
                }
            }
        }

        else {
            Write-Host "Unexpected situation, should not occur"
            Exit-PSSession
        }

        Write-Host '--------------------------------------------------------------------------------------------------------------------------'
        Write-Host " "
    }

    # Type VM VM Affinity is Keep VMs together
    $output=Get-DrsRule -Cluster $Cluster -Type VMAffinity | Select-Object Cluster,Name,Type,Enabled, @{N="VMnames";E={ $_.Vmids|%{(get-view -id $_).name}}}, @{N="PowerState";E={ $_.Vmids|%{(get-view -id $_).Runtime.PowerState}}}
    $output >> $OutFile

    #Number of rules in Cluster is equal to: $output.Cluster.Count
    for ($i=0; $i -lt $output.Cluster.Count; $i++) {
        Write-Host "Rule name   :" $output[$i].Name

        #rule enabled
        if ( $output[$i].Enabled -eq "True" ) {
            Write-Host "Rule Enabled: Yes."
        }
        else {
            Write-Host "Rule Enabled: No. So don't worry about the next lines now"
        }

        Write-Host "Type        : Keep Virtual Machines together"

        # Array for Hosts
        $hosts = @()    
        # Number of VMs is equal to: $output[$i].VMnames.Count
        for ($j=0; $j -lt $output[$i].VMnames.Count; $j++) {
            $realhost = Get-VM -Name $output[$i].VMnames[$j] | Select-Object VMHost
            $hosts += $realhost.VMhost.Name
            Write-Host "VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "is placed on host " $hosts[$j]
        }   

        # Test Array for hosts, must be all equal
        $flag="OK, All VMs reside on the same host."
        for ($j=1; $j -lt $hosts.Count; $j++) {
            if ( $hosts[0] -ne $hosts[$j] ) {
                $flag="ERROR, not all VMs reside on the same host."
                break
            }
        } 
        
        $flag
   
        Write-Host '--------------------------------------------------------------------------------------------------------------------------'
        Write-Host " "
    }

    # Type VM VM Anti Affintity = Seperate VMs
    $output=Get-DrsRule -Cluster $Cluster -Type VMAntiAffinity | Select-Object Cluster,Name,Type,Enabled, @{N="VMnames";E={ $_.Vmids|%{(get-view -id $_).name}}}, @{N="PowerState";E={ $_.Vmids|%{(get-view -id $_).Runtime.PowerState}}}
    $output >> $OutFile

    #Number of rules in Cluster is equal to: $output.Cluster.Count
    for ($i=0; $i -lt $output.Cluster.Count; $i++) {
        Write-Host "Rule name   :" $output[$i].Name

        #rule enabled
        if ( $output[$i].Enabled -eq "True" ) {
            Write-Host "Rule Enabled: Yes."
        }
        else {
            Write-Host "Rule Enabled: No. So don't worry about the next lines now"
        }

        Write-Host "Type        : Keep Virtual Machines separated"

        # Array for Hosts
        $hosts = @()    
        # Number of VMs is equal to: $output[$i].VMnames.Count
        for ($j=0; $j -lt $output[$i].VMnames.Count; $j++) {
            $realhost = Get-VM -Name $output[$i].VMnames[$j] | Select-Object VMHost
            $hosts += $realhost.VMhost.Name
            Write-Host "VM" $output[$i].VMnames[$j] ", Power State:" $output[$i].PowerState[$j] "is placed on host " $hosts[$j]
        }   

        # Test Array for hosts, must all be different
        $flag="OK, All VMs reside on different host."
        for ($j=0; $j -lt $hosts.Count; $j++) {
            for ($k=$j+1; $k -lt $hosts.Count; $k++) {
                if ( $hosts[$j] -eq $hosts[$k] ) {
                    $flag="ERROR, not all VMs reside on different host."
                    break
                }
            }
        } 
        
        $flag
   
        Write-Host '--------------------------------------------------------------------------------------------------------------------------'
        Write-Host " "
    }

}   # for-each Cluster loop ends here
#EOF
