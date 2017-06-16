# Get-ClusterRules
PowerShell script for retrieving and checking DRS rules for vSphere Clusters

Script Get-ClusterRules needs some improvement:
1. Especially in large environments, you should not stress the vCenter Server time after time
   and pull all required information in one action from the vCenter database with this line:
   $output=Get-DrsRule etc...
   However the $realhost = Get-VM -Name etc. means an extra action.
   For performance $realhost should be retrieved during the $output action with get-view.

2. Checks are now sent to the screen, a bit more fancier (color) output would be nice.
   
