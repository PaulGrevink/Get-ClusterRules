# Get-ClusterRules
PowerShell script for retrieving and checking DRS rules for vSphere Clusters

Script Get-ClusterRules needs some improvement:
1. Especially in large environments, you should not stress the vCenter Server and pull
   are required information in one action from the vCenter database with this line:
   $output=Get-DrsRule etc...
   However the $realhost = Get-VM -Name etc. means an extra action.
   For performance realhost should be retrieved during the $output action with get-view.
   
