#
# Script.ps1
#
# Import modules
# Import-AzureRM

#Global variables
$subscriptionGUID = "e9f6f353-b86c-4d91-a0aa-2d38e557cacc"
$rgName = "DEP01-INT"
$lbName = "DEP01-INT-DMZ-SWARM1-LBPUB"

function AzureRMLogin {
	param (
		[string] [Parameter(Mandatory=$true)] $subscriptionGUID
	)
	Login-AzureRmAccount
	Select-AzureRmSubscription -SubscriptionId $subscriptionGUID
}

function AzureRMProfile {
    param (
        [string] [Parameter(Mandatory=$true)] $Path
    )
    Select-AzureRmProfile -Path $Path
}

function SetLoadBalancingRules {
	param(
        [string] $resourceGroupName,
		[string] $loadBalancerName,
		[array] $rules
	)

	#Get the Load Balancer
	$slb = Get-AzureRmLoadBalancer -Name $loadBalancerName -ResourceGroupName $resourceGroupName

	#Get FrontEnd IP config
	$feipconfig = $slb | Get-AzureRmLoadBalancerFrontendIpConfig
	#Get Backend Pool
	$bepool = $slb | Get-AzureRmLoadBalancerBackendAddressPoolConfig

    #Empty LoadBalancer probes and LoadBalancing rules
    $slb.Probes = @()
    $slb.LoadBalancingRules = @()

    # Create all probes and rules according to definition
	foreach ($rule in $rules) {
		if ($rule.protocol -eq "HTTP") {
		    #Create new Probe
		    $probe = New-AzureRmLoadBalancerProbeConfig -Name ("probe_" + $rule.portName) -RequestPath $rule.requestPatush -Protocol http -Port $rule.bPort -IntervalInSeconds 5 -ProbeCount 2
		    $slb | Add-AzureRmLoadBalancerProbeConfig -Name ("probe_" + $rule.portName) -RequestPath $rule.requestPath -Protocol http -Port $rule.bPort -IntervalInSeconds 5 -ProbeCount 2
		} else {
			$probe = New-AzureRmLoadBalancerProbeConfig -Name ("probe_" + $rule.portName) -Protocol tcp -Port $rule.bPort -IntervalInSeconds 5 -ProbeCount 2
		    $slb | Add-AzureRmLoadBalancerProbeConfig -Name ("probe_" + $rule.portName) -Protocol tcp -Port $rule.bPort -IntervalInSeconds 5 -ProbeCount 2
		}
        
		#Create Load Balancing Rule
		$slb | Add-AzureRmLoadBalancerRuleConfig -Name ("rule_" + $rule.portName) -FrontendIpConfiguration $feipconfig -BackendAddressPool $bepool -Probe $probe -Protocol TCP -FrontendPort $rule.fPort -BackendPort $rule.bPort
 	}

	#Save the new configuration
	$slb | Set-AzureRmLoadBalancer
}

#AzureRMLogin($subscriptionGUID)


$loadBalancersRules = (Get-Content "LoadBalancerRules.json") -join "`n" | ConvertFrom-Json

foreach ($loadBalancer in $loadBalancersRules) {

    SetLoadBalancingRules -ResourceGroupName $loadBalancer.resourceGroupName -LoadBalancerName $loadBalancer.name -Rules $loadBalancer.LBRules
}
