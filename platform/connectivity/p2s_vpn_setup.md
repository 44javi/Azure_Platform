# P2S VPN Client Setup — Basic SKU + Certificate Auth (IKEv2)

## Variables

Edit these before running any commands:

```powershell
$GatewayName   = ""
$ResourceGroup = ""
$KeyVaultName  = ""
$KVSecretName  = "p2s-root-cert-data"
$GatewayFQDN   = ""
$VpnClientPool = ""   # IPs assigned to connected clients
$CertOutputDir = "C:\Users\$env:USERNAME\Downloads"
```

---

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- PowerShell 5.1+ (Windows built-in)
- Terraform already applied with `vpn_auth_types = ["Certificate"]` and `vpn_client_protocols = ["IkeV2"]`

---

## One-Time Setup: Root CA + Gateway Upload

Run once per environment. The root CA stays in Azure; client certs are issued from it.

### 1. Generate the root CA cert

```powershell
$rootCA = New-SelfSignedCertificate `
  -Type Custom -KeySpec Signature `
  -Subject "CN=P2SRootCert" `
  -KeyExportPolicy Exportable `
  -HashAlgorithm sha256 -KeyLength 2048 `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -KeyUsageProperty Sign -KeyUsage CertSign
```

> **Important:** `New-SelfSignedCertificate` must include `-KeyUsage CertSign`. Without it the cert is created as a leaf cert (CA:FALSE) and Azure will reject all client certs signed by it.

### 2. Upload the root CA to the Azure VPN gateway

```powershell
$pemContent = "-----BEGIN CERTIFICATE-----`r`n" + `
  [Convert]::ToBase64String($rootCA.RawData, [System.Base64FormattingOptions]::InsertLineBreaks) + `
  "`r`n-----END CERTIFICATE-----"
Set-Content "$CertOutputDir\rootcert.pem" -Value $pemContent -Encoding ASCII

az network vnet-gateway root-cert create `
  --gateway-name $GatewayName `
  --resource-group $ResourceGroup `
  --name P2SRootCert `
  --public-cert-data "$CertOutputDir\rootcert.pem"
```

> The gateway takes **2–3 minutes** to update after this command.

### 3. Terraform cert drift

`vpn_gateway.tf` uses `ignore_changes = [vpn_client_configuration[0].root_certificate]` so Terraform will **not** revert the root cert on `apply`.

> Key Vault cannot store certificates with `CertSign` key usage (required for a proper root CA), so the cert is managed outside Terraform. To rotate, re-run steps 1–2 and upload via `az network vnet-gateway root-cert create`.

---

## Per-Machine Setup: Client Cert + VPN Connection

Run on every machine that needs VPN access.

### 4. Generate a client cert (requires the root CA in `CurrentUser\My`)

```powershell
$rootCA = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -eq "CN=P2SRootCert" } | Select-Object -First 1

$clientCert = New-SelfSignedCertificate `
  -Type Custom -DnsName P2SChildCert `
  -KeySpec Signature `
  -Subject "CN=P2SChildCert" `
  -KeyExportPolicy Exportable `
  -HashAlgorithm sha256 -KeyLength 2048 `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -Signer $rootCA `
  -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
```

### 5. Install certs in the machine store

```powershell
# Trust the root CA machine-wide
Export-Certificate -Cert $rootCA -FilePath "$CertOutputDir\rootCA.cer"
Import-Certificate -FilePath "$CertOutputDir\rootCA.cer" -CertStoreLocation "Cert:\LocalMachine\Root"

# Install client cert in machine store (required for IKEv2)
$pfxPwd = ConvertTo-SecureString "Temp123!" -AsPlainText -Force
Export-PfxCertificate -Cert $clientCert -FilePath "$CertOutputDir\clientcert.pfx" -Password $pfxPwd
Import-PfxCertificate -FilePath "$CertOutputDir\clientcert.pfx" -CertStoreLocation "Cert:\LocalMachine\My" -Password $pfxPwd
```

### 6. Create the VPN connection

```powershell
[xml]$eapConfig = Get-Content "C:\Users\$env:USERNAME\eap-tls.xml" -Raw

Add-VpnConnection `
  -Name "Azure-P2S" `
  -ServerAddress $GatewayFQDN `
  -TunnelType IKEv2 `
  -AuthenticationMethod Eap `
  -EapConfigXmlStream $eapConfig `
  -EncryptionLevel Required `
  -SplitTunneling `
  -RememberCredential `
  -Force
```

The `eap-tls.xml` file is in this directory. Copy it to `C:\Users\<you>\` before running.

> **Split tunneling is enabled** — only VNet traffic routes through the VPN. Internet and Azure portal use your normal connection.

### 7. Connect

Open **Settings → Network & Internet → VPN** and connect to **Azure-P2S**.

---

## Adding VPN Access for a New User / Machine

If the root CA already exists and is uploaded to Azure, skip steps 1–3. You only need to:

1. Export the root CA private key from an existing machine:
   ```powershell
   $rootCA = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -eq "CN=P2SRootCert" }
   $pwd = ConvertTo-SecureString "ExportPassword" -AsPlainText -Force
   Export-PfxCertificate -Cert $rootCA -FilePath "rootCA-private.pfx" -Password $pwd
   ```
2. Transfer `rootCA-private.pfx` to the new machine and import it into `Cert:\CurrentUser\My`
3. Run steps 4–7 on the new machine

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| Error 798 — certificate not found | No client cert in store | Run steps 4–5 |
| Error 1244 — not authenticated | Chain invalid or wrong CA in Azure | Verify root CA thumbprint matches Azure: see check below |
| IKE failed to find valid certificate | Wrong auth method | Ensure VPN connection uses `Eap`, not `MachineCertificate` |
| No internet while connected | Force tunnel enabled | Recreate connection with `-SplitTunneling` flag |

**Verify root CA matches Azure:**
```powershell
$certDataB64 = az network vnet-gateway show --name $GatewayName --resource-group $ResourceGroup --query "vpnClientConfiguration.vpnClientRootCertificates[0].publicCertData" --output tsv
$azureCert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([Convert]::FromBase64String($certDataB64))
$localRoot = Get-ChildItem "Cert:\LocalMachine\Root" | Where-Object { $_.Subject -like "*P2SRootCert*" }
Write-Host "Match: $($azureCert.Thumbprint -eq $localRoot.Thumbprint)"
```
