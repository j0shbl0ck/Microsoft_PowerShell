# 🚀 Most Commonly Used PowerShell Scripts

A personal quick-access list of frequently used PowerShell scripts for managing Microsoft 365, Entra ID, Exchange, and local systems.

> 🧭 Think of this as a **bookmark bar** for your script essentials.  
> Test all scripts before use in production environments.

---

## 📁 Quick Access Index

| 🧩 **Category**           | 📜 **Example Scripts**                                                                 |
|--------------------------|----------------------------------------------------------------------------------------|
| **Exchange Online**      | [✅ Allow Quarantined Device](https://github.com/j0shbl0ck/Microsoft_PowerShell/blob/main/Entra%20ID/Exchange%20Online/Mail%20Security/Security%20%26%20External%20Mail/allow-quaran-device.ps1) ・ [👥 Bulk Create Users](#👥-bulk-create-users)         |
| **Mailbox Tools**        | [📬 Mailbox Permissions](#📬-mailbox-permissions) ・ [📤 Shared Mailbox Convert](#📤-shared-mailbox-convert) |
| **User Management**  | [💀 Termed User Access](https://github.com/j0shbl0ck/Microsoft_PowerShell/blob/main/Entra%20ID/User%20Management/set_user_termed_access.ps1) ・ [👁‍🗨 View Sign-ins](#👁‍🗨-view-sign-ins)           |
| **Security / Compliance**| [🛡 Disable Legacy Auth](#🛡-disable-legacy-auth) ・ [🔒 MFA Report](#🔒-mfa-report)             |

---

## 🔑 Reset Password
> Quickly reset a user's password in Entra ID and force sign-out.

🔗 [`reset-password.ps1`](./scripts/reset-password.ps1)

```powershell
Set-MsolUserPassword -UserPrincipalName user@domain.com -NewPassword "NewP@ssw0rd" -ForceChangePassword $true
```