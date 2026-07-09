# Lab 02 — Storage, Database & Application Services

---

## Overview

This lab covers the data and application layer of Azure — provisioning a Storage Account for blob/file storage, deploying Azure SQL Database, and connecting it to an App Service-hosted API. It demonstrates how compute, data, and storage services are secured and integrated together, not just spun up in isolation.

---

## Problem / Scenario

Most real applications need three things working together: a place to store files, a database for structured data, and a web layer to serve it all. This lab simulates standing up that stack for a small internal application — the kind of setup a financial services company might use for an internal reporting tool — with security applied at every layer rather than left on defaults.

**Requirements addressed:**
- Storage must not be publicly accessible by default
- The database must only accept connections from trusted sources
- The application layer must connect to the database securely, with no credentials exposed in code

---

## Architecture

```
                ┌──────────────────────────┐
                │   Resource Group              │
                └──────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────────────┐   ┌───────────────────┐   ┌───────────────────┐
│ Storage Account │   │  App Service        │   │  Azure SQL Server   │
│  (Blob/File)     │   │  (Hosts API)         │──▶│  + SQL Database      │
│  Private access  │   │                     │   │  Firewall: App only  │
└───────────────┘   └───────────────────┘   └───────────────────┘
```

*(Full diagram in `architecture-diagram.png`)*

---

## Implementation

**Tools used:** ARM Templates, Azure CLI, PowerShell, Azure Portal (verification)

1. Provisioned a Storage Account with `allowBlobPublicAccess` disabled and TLS 1.2 enforced as the minimum
2. Created a blob container for application file storage with private access level
3. Deployed an Azure SQL Server and SQL Database, with firewall rules restricting access to Azure services only (no public "Allow all IPs" rule)
4. Deployed an App Service and configured its connection string to the SQL Database via Application Settings (not hardcoded in any file)
5. Verified the API could read/write to the database, and that direct external connections to the database were rejected

Deployment is handled via ARM templates in [`arm-templates/`](./arm-templates), with the firewall configuration applied through [`scripts/configure-firewall.ps1`](./scripts/configure-firewall.ps1).

```bash
az deployment group create \
  --resource-group rg-storage-lab \
  --template-file arm-templates/storage-account.json \
  --parameters storageAccountName=stdatalab01
```

---

## Security Decisions

| Decision | Reasoning |
|---|---|
| Disabled public blob access | Prevents accidental public exposure of stored files — a common real-world data leak cause |
| TLS 1.2 minimum on storage | Enforces encrypted data in transit |
| SQL firewall set to "Azure services only" | Database is not reachable from the open internet at all, only from within Azure |
| Connection string in App Service settings, not code | Prevents credentials from ever being committed to source control |

---

## Outcome / Proof

- ✅ Storage Account confirmed private — direct anonymous blob URL access returns 404/403
- ✅ SQL Database reachable from App Service, unreachable from external IP (tested directly)
- ✅ App Service successfully serving data pulled from Azure SQL

| Screenshot | Description |
|---|---|
| `01-storage-account.png` | Storage account configuration showing public access disabled |
| `02-blob-container.png` | Container access level set to Private |
| `03-sql-database.png` | SQL Database firewall rules configuration |
| `04-app-service-live.png` | App Service running and connected to database |

---

## What I'd Improve Next

- Move database credentials into Azure Key Vault instead of App Service settings directly
- Add a Private Endpoint for the SQL Database to remove it from any public network path entirely
- Implement Azure SQL auditing and Defender for SQL for threat detection

---

## Estimated Cost

Approximately **$20–35/month** if left running (Basic App Service Plan + Basic SQL tier + Standard Storage). Resources are deprovisioned after each session to control cost.

---
