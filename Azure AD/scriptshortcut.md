# 🚀 Most Commonly Used PowerShell Scripts

A personal quick-access list of frequently used PowerShell scripts for managing Microsoft 365, Entra ID, Exchange, and local systems.

> 🧭 Think of this as a **bookmark bar** for your script essentials.  
> Test all scripts before use in production environments.

---

## 📁 Quick Access Index

| 🧩 **Category**           | 📜 **Example Scripts**                                                                 |
|--------------------------|----------------------------------------------------------------------------------------|
| **User Management**      | [🔑 Reset Password](#🔑-reset-password) ・ [👥 Bulk Create Users](#👥-bulk-create-users)         |
| **Mailbox Tools**        | [📬 Mailbox Permissions](#📬-mailbox-permissions) ・ [📤 Shared Mailbox Convert](#📤-shared-mailbox-convert) |
| **Entra ID / Azure AD**  | [🔍 ImmutableID Match](#🔍-immutableid-match) ・ [👁‍🗨 View Sign-ins](#👁‍🗨-view-sign-ins)           |
| **Security / Compliance**| [🛡 Disable Legacy Auth](#🛡-disable-legacy-auth) ・ [🔒 MFA Report](#🔒-mfa-report)             |
| **System Tools**         | [🧹 Temp File Cleanup](#🧹-temp-file-cleanup) ・ [🧪 Defender Scan](#🧪-defender-scan)             |

---

## 🔑 Reset Password
> Quickly reset a user's password in Entra ID and force sign-out.

🔗 [`reset-password.ps1`](./scripts/reset-password.ps1)

```powershell
Set-MsolUserPassword -UserPrincipalName user@domain.com -NewPassword "NewP@ssw0rd" -ForceChangePassword $true
```