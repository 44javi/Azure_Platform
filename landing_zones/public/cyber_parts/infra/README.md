# SharePoint → Azure AI Search Connection Guide

> Secretless setup using federated credentials (workload identity federation).

---

## Architecture

```
SharePoint Online (Communication Site)
  └── Document Library: KB - Website Agent
        │
        │  crawled on schedule
        ▼
  Azure AI Search Indexer
        │  authenticates via
        ▼
  Entra ID App Registration
        ├── Federated credential → Search Service Managed Identity
        ├── Microsoft Graph    → Files.Read.selected (Application) 
        └── SharePoint API     → Sites.Selected (Application)
        │
        ▼
  Azure AI Search Index
        │  queried by
        ▼
  Azure AI Foundry Knowledge Base
        │
        ▼
  AI Agent
```

---

## Prerequisites

- Azure AI Search — Basic SKU or higher
- SharePoint Online (Microsoft 365) — OneDrive is not supported
- System-assigned managed identity enabled on the Azure AI Search service
- Entra ID permissions to create app registrations and grant admin consent
- SharePoint site admin access
- PowerShell with `PnP.PowerShell` module installed

---

## Step 1 — Enable Managed Identity on Search Service

1. Go to your Azure AI Search resource → **Settings → Identity**
2. Set System assigned status to **On** → Save

---

## Step 2 — Create the App Registration

1. Entra ID → App registrations → **New registration**
2. Name: `sp-srch-public-agents`
3. Supported account types: **Single tenant**
4. No redirect URI needed → Register

### Add API Permissions

Add permissions under **two separate APIs**:

| API | Permission | Type |
|---|---|---|
| **Microsoft Graph** | `Files.SelectedOperations.Selected` | Application |
| **Microsoft Graph** | `Sites.Selected` | Application |


After adding both → click **Grant admin consent**.

---

## Step 3 — Configure Federated Credential

1. App registration → **Certificates & secrets → Federated credentials**
2. Click **Add credential**
3. Fill in the fields:

| Field | Value |
|---|---|
| Scenario | Other issuer |
| Issuer | `leave the default` |
| Subject identifier | `select the managed identity for the search service` |
| Name | `srch-managed-identity` |

4. Save → copy the **Federated credential object ID** shown after saving

---

## Step 4 — Grant Sites.Selected Access via PowerShell (Left here)

`Sites.Selected` cannot be scoped to a specific site through the Azure portal.
This PowerShell grant is required once per site.

```powershell
# Install PnP.PowerShell if not already installed
Install-Module -Name PnP.PowerShell -Force

# Connect to your SharePoint site
Connect-PnPOnline `
  -Url "https://cyberneticnimbus.sharepoint.com/sites/CNPublicAgents" `
  -Interactive

# Grant the app registration read access to this specific site
# Use the Application (client) ID from Step 2 — not the object ID
Grant-PnPAzureADAppSitePermission `
  -AppId "{application-client-id}" `
  -DisplayName "sp-srch-public-agents" `
  -Site "https://cyberneticnimbus.sharepoint.com/sites/CNPublicAgents" `
  -Permissions Read

# Verify the grant was applied
Get-PnPAzureADAppSitePermission `
  -Site "https://cyberneticnimbus.sharepoint.com/sites/CNPublicAgents"
```

---

## Step 5 — Create the Knowledge Source in AI Foundry

AI Foundry → AI Search resource → Knowledge bases → Create new →
**Microsoft SharePoint (Indexed)** → Identity fields

| Field | Value |
|---|---|
| SharePoint endpoint | `https://cyberneticnimbus.sharepoint.com/sites/CNPublicAgents` |
| Application ID | `{application client ID from Step 2}` |
| Federated credential object ID | `{federated credential object ID from Step 3}` |
| Tenant ID | `{your Entra tenant GUID}` |
| Container name | Use custom query |
| Query | `path:"https://cyberneticnimbus.sharepoint.com/sites/CNPublicAgents/KB - Website Agent"` |
| Content extraction mode | Minimal |
| Authenticate using managed identity | Checked |
| Managed identity type | System-assigned |

---

## Step 6 — Verify Indexer Run

1. Azure AI Search → **Indexers**
2. Find the indexer created by Foundry → **Run now**
3. Check execution history — status should show **Success** with document count > 0
4. If status shows errors, check for:
   - `403` — auth not configured correctly, recheck Steps 3 and 4
   - `0 documents` — path in the query field does not match the library URL exactly

---

## Known Limitations

### Content Extraction: Minimal Only in North Central US
Standard extraction mode (full skillset support — chunking, embeddings, custom
enrichment) is not available in North Central US. Only Minimal mode is supported
in this region.

Supported regions for Standard mode: `eastus`, `eastus2`, `westus`, `westus3`,
`southcentralus`, `westeurope`, `northeurope`, `uksouth`, `swedencentral`,
`australiaeast`, `southeastasia`, `japaneast`

**Impact:** For a production agent with full RAG pipeline (vector search, semantic
ranking), the search service must be deployed in one of the supported regions above.

---

### No Private Endpoint Support
The SharePoint connector requires a publicly routable network path. It cannot
traverse private endpoints on the search service.

**Impact:** The search service must allow public network access for the SharePoint
indexer to function, even if all other access is restricted.

**Workaround:** Use the search service firewall to restrict public access to
trusted IP ranges only. Long-term, migrate to blob storage as the knowledge
source — blob indexers fully support private endpoints.

---

### No Conditional Access Support
If the Entra tenant has Conditional Access policies scoped to SharePoint Online
or Microsoft Graph, the indexer service principal will be blocked.

**Workaround:** Exclude the app registration from relevant CA policies or configure
a trusted named location exclusion for the search service.

---

### Incremental Indexing Breaks on Folder Rename
Renaming a document library or folder causes the indexer to treat all content
under the renamed path as new — triggering full re-indexing and potential
duplicate documents in the index.

**Rule:** Treat library and folder names as permanent once the indexer is configured.
The `KB - Website Agent` library name should never be changed.

---

### Sites.Selected Requires PowerShell Per Site
The `Sites.Selected` permission cannot be scoped to a specific site through the
Azure portal. The PnP PowerShell grant in Step 4 must be run manually once per
site and once per app registration.

**Rule:** When adding a new SharePoint site as a knowledge source, re-run the
`Grant-PnPAzureADAppSitePermission` command targeting the new site before
creating the indexer.

---

### Files.Read.All Not in SharePoint API Picker
This is a Microsoft Graph permission and will not appear when searching under
the SharePoint API in the portal permissions picker.

**Rule:** Always add `Files.Read.All` under **Microsoft Graph → Application
permissions**, not under SharePoint.

---

### OneNote Notebooks Not Supported
Files with the `.one` extension are silently skipped by the indexer.

**Workaround:** Export any OneNote content to `.md` or `.docx` before placing
it in the library.

---

## Long-Term: Migrate to Blob Storage

For production public-facing agents, Azure Blob Storage is the recommended
knowledge source over SharePoint:

| | SharePoint (Indexed) | Blob Storage |
|---|---|---|
| Private endpoints | ❌ Not supported | ✅ Supported |
| All extraction modes | ❌ Region-limited | ✅ All regions |
| Conditional Access conflicts | ⚠️ Possible | ✅ Not applicable |
| Update workflow | Manual file upload via SharePoint UI | Pipeline push to container |
| Auth | Federated credential + PnP grant | Managed identity (simpler) |

Migration steps when ready:

1. Create a storage account and blob container
2. Copy `.md` files from SharePoint library to the container
3. Create a new data source in AI Search pointing at the blob container
4. Create a new indexer using the blob data source
5. Update the knowledge base in Foundry to point at the new index
6. Decommission the SharePoint data source and indexer
