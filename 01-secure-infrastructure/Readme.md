
# Secure Infrastructure Deployment 
---
 
## Overview
 
This lab designs and deploys a secure virtual network foundation in Azure, using Azure Bastion to provide administrative access to a Windows Server VM with no direct public exposure. It demonstrates network segmentation, NSG hardening on both the workload and management subnets, and a secure remote access pattern — built entirely with Terraform.
 
---
 
## Problem / Scenario
 
A common security failure in cloud environments is exposing a VM's RDP port directly to the internet, even when restricted to a single IP. This lab goes a step further than basic IP-restricted RDP by removing the VM's public exposure entirely and routing all administrative access through Azure Bastion — Microsoft's managed jump-host service. This reflects how a real organisation would secure administrative access to production workloads.
 
**Requirements addressed:**
- The VM must have no public IP and no direct internet-facing RDP port
- Administrative access must go through a managed, audited bastion host
- Each subnet must be protected by its own NSG, scoped to that subnet's actual traffic needs
- Network must be segmented, not a single flat address space
---
 
## Architecture
 
```
                    ┌──────────────────────────────────┐
                    │      Resource Group: Secure-Lab-RG     │
                    └──────────────────────────────────┘
                                      │
                    ┌──────────────────────────────────┐
                    │     VNet: vnet1-hub-prod                │
                    │        10.0.0.0/16                       │
                    └──────────────────────────────────┘
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            │                                                   │
┌───────────────────────────┐                     ┌───────────────────────────┐
│  Subnet: AzureBastionSubnet  │                     │  Subnet: vm-subnet1          │
│   10.0.3.0/24                 │                     │   10.0.1.0/24                 │
│                               │                     │                               │
│  NSG: bastion-nsg             │                     │  NSG: NetworkSecurityGroup1   │
│  • Allow 443 from Internet    │                     │  • Allow RDP ← Admin IP only  │
│  • Allow GatewayManager       │                     │  • Deny all other inbound     │
│  • Allow AzureLoadBalancer    │                     │                               │
│  • Allow Bastion host comms   │                     │  VM: vm-win-secure            │
│  • Outbound rules per MS spec │ ───(RDP via Bastion)▶│  Windows Server 2022          │
│                               │                     │  No public IP                │
└───────────────────────────┘                     └───────────────────────────┘
```
 
*(Full diagram exported separately as `architecture-diagram.png`)*
 
---
 
## Implementation
 
**Tools used:** Terraform, Azure CLI, Azure Portal (verification)
 
1. Provisioned a resource group to contain all lab resources
2. Created a virtual network (`10.0.0.0/16`) with two subnets:
   - `vm-subnet1` (`10.0.1.0/24`) for the workload VM
   - `AzureBastionSubnet` (`10.0.3.0/24`) — the specifically-named subnet required for Azure Bastion
3. Built a dedicated NSG for the Bastion subnet, applying Microsoft's documented required rule set (HTTPS inbound from Internet, GatewayManager, AzureLoadBalancer, and Bastion host-to-host communication on ports 8080/5701, plus the matching outbound rules)
4. Built a separate NSG for the VM subnet, allowing RDP only from a single administrator IP and explicitly denying all other inbound traffic
5. Associated each NSG with its correct subnet
6. Deployed a Windows Server 2022 VM into `vm-subnet1` with no public IP assigned
7. Verified administrative access to the VM through Azure Bastion in the Azure Portal
All infrastructure is defined in [`terraform/main.tf`](./terraform/main.tf), parameterised via [`terraform/variables.tf`](./terraform/variables.tf). No credentials, IPs, or secrets are hardcoded in the committed code — they are supplied through `terraform.tfvars`, which is excluded from version control.
 
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```
 
---
 
## Security Decisions
 
| Decision | Reasoning |
|---|---|
| Azure Bastion instead of exposed RDP | Removes any public-facing RDP port entirely, administrative access is brokered through Microsoft's managed service over HTTPS (443), which is harder to attack than an open RDP port even when IP-restricted |
| VM has no public IP | Without Bastion, there is no way to reach the VM directly from the internet at all |
| Two separate NSGs, one per subnet | The Bastion subnet and the VM subnet have very different traffic requirements, scoping rules per subnet keeps each NSG minimal and auditable rather than one shared, overly broad rule set |
| Explicit deny-all on the VM subnet NSG | Default-deny posture — only the specific RDP rule from the admin IP is permitted, everything else is rejected by default |
| Admin IP and credentials passed as variables, not hardcoded | Prevents committing sensitive values to source control, a mistake present in the first draft of this lab's code before this fix |
| Infrastructure as Code (Terraform) | Ensures the configuration is repeatable, auditable, and version-controlled rather than manually clicked in the Portal |
 
---
 
## A Real Mistake I Caught and Fixed
 
While building this lab, the first version of the code created `NetworkSecurityGroup1` but never associated it with the VM subnet — meaning the VM subnet was effectively unprotected by any NSG despite the NSG existing in the configuration. It also had the admin password and admin IP hardcoded directly in `main.tf`. Both were caught during review and fixed by:
- Adding the missing `azurerm_subnet_network_security_group_association` resource to actually attach the NSG to the VM subnet
- Moving the password, admin username, and admin IP into `variables.tf`, supplied via a local `terraform.tfvars` file that is excluded from Git
This is included here deliberately — catching a misconfigured or missing security association before deployment, rather than after, is exactly the kind of review discipline this lab is meant to demonstrate.
 
---
 
## Outcome / Proof
 
- ✅ VM deployed with no public IP, confirmed unreachable from the public internet directly
- ✅ Administrative RDP session successfully established through Azure Bastion
- ✅ NSG rules verified correctly associated with their respective subnets in the Azure Portal
- ✅ Direct RDP attempt to the VM's private IP from outside the VNet confirmed blocked
| Screenshot | Description |
|---|---|
| `01-vnet-subnets.png` | VNet showing both subnets and their address ranges |
| `02-nsg-associations.png` | Both NSGs shown correctly associated with their subnets |
| `03-bastion-session.png` | Successful RDP session via Azure Bastion |
| `04-vm-no-public-ip.png` | VM overview confirming no public IP assigned |
 
---
 
## What I'd Improve Next
 
- Move `admin_password` to Azure Key Vault and reference it via a data source instead of a plain Terraform variable
- Add Azure Policy to enforce that no future VM in this resource group can be assigned a public IP
- Right-size the VM further if lab usage allows — currently using a deliberately modest size to manage cost
---
 
## Estimated Cost
 
Approximately **$25–35/month** if left running continuously (VM + Azure Bastion Basic SKU, which has a fixed hourly cost regardless of usage + Standard NSGs). Azure Bastion in particular has a non-trivial always-on cost, so resources are deprovisioned with `terraform destroy` after each lab session.
 
---
 
**← [Back to Portfolio Overview](../README.md)**
 


