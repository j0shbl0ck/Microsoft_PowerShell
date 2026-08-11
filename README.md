# ⚡ Microsoft PowerShell Toolkit

A curated collection of PowerShell scripts for managing Microsoft environments — **tenants**, **mailboxes**, **users**, **groups**, and more — spanning on-prem Active Directory through Exchange Online, Entra ID, and endpoint tooling.

<p>
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white" alt="PowerShell 5.1+"/>
  <img src="https://img.shields.io/badge/Categories-4-blue" alt="4 Categories"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
  <img src="https://img.shields.io/badge/Author-j0shbl0ck-black?logo=github" alt="Author"/>
</p>

> 🧪 All scripts are provided **as-is**. Test in a controlled environment before deploying to production — several are tenant-wide/bulk operations.

Jump to a category 👇

<table>
<tr>
<td width="25%">

🗃️ [Active Directory](#️-active-directory)

</td>
<td width="25%">

🔒 [Azure AD](#-azure-ad)

</td>
<td width="25%">

🆔 [Entra ID](#-entra-id)

</td>
<td width="25%">

🛠️ [Scripts](#️-scripts)

</td>
</tr>
</table>

---

## 🗃️ Active Directory

On-prem AD attribute management and Azure AD Connect / hybrid sync tasks.

<details open>
<summary><strong>2 subfolders · 5 scripts</strong></summary>

| 📁 **Item** | 📜 **Description** |
| --- | :--- |
| `Azure AD Connect/` | Scripts for managing Azure AD Connect / hybrid sync tasks. |
| `Import_Users_CSV/` | Bulk user import tooling driven by CSV. |
| `Change_User_CN.ps1` | Updates a user's Common Name (CN) in on-prem AD. |
| `Export_User_Group_Info.ps1` | Exports user and group membership info from AD. |
| `Get_True_msExchHideFromAddressLists.ps1` | Reports the *effective* `msExchHideFromAddressLists` value for users. |
| `Rmv_msExch_Attrbtes.ps1` | Removes legacy/orphaned Exchange (`msExch*`) attributes from AD objects. |
| `Update_userInformation.ps1` | Bulk-updates AD user attribute fields. |

</details>

## 🔒 Azure AD

Tools for **Exchange Online**, **SharePoint Online**, Microsoft MFA, Purview, and Azure AD/M365 user management.

<details open>
<summary><strong>5 subfolders</strong></summary>

| 📁 **Folder** | 📜 **Description** |
| --- | :--- |
| [`Exchange Online/`](Azure%20AD/Exchange%20Online/README.md) | 50+ scripts across 13 categories — mailboxes, distribution lists, contacts, calendar permissions, compliance/retention, mail security, and reporting. See its dedicated README for the full breakdown. |
| `Microsoft MFA/` | MFA reporting and configuration scripts. |
| `Purview/` | Microsoft Purview compliance scripts. |
| `SharePoint Online/` | SharePoint Online administration scripts. |
| `User Management/` | Azure AD / M365 user lifecycle scripts (e.g., termed user access). |

Also includes its own [Quick Access README](Azure%20AD/README.md) — a bookmark-bar style index of the most frequently used scripts in this category.

</details>

## 🆔 Entra ID

⚠️ Scripts using legacy Entra ID cmdlets — retained for reference, superseded where possible by the modern Microsoft Graph SDK.

<details open>
<summary><strong>4 scripts</strong></summary>

| 📜 **Script** | 📄 **Description** |
| --- | :--- |
| `disable_user.ps1` | Disables a user account in Entra ID. |
| `find-e3-assignment-30-day.ps1` | Finds users with an E3 license assignment within the last 30 days. |
| `mail_entrpse_apps.ps1` | Reports on mail-related enterprise app registrations. |
| `user_photo.ps1` | Manages/uploads user profile photos in Entra ID. |

</details>

## 🛠️ Scripts

Helper scripts for RMM automation and Windows system administration.

<details open>
<summary><strong>2 subfolders</strong></summary>

| 📁 **Folder** | 📜 **Description** |
| --- | :--- |
| `Datto_RMM/` | Scripts built for/around Datto RMM automation. |
| `Windows_System/` | General Windows system administration and OS-level tasks. |

</details>

---

## 📌 Script Standards

Each script aims to follow a clean, consistent format:

- **Filename Format**: `verb-action-target.ps1`
  _Example: `set-password-expiration.ps1`_

- **Header Block**:
  ```powershell
  <#
  .SYNOPSIS     Short description of the script
  .NOTES        Contains Author, Date, Type, Version, and Links
  .LINK         Relevant links for further information
  #>
  ```

## 📄 License

Released under the [MIT License](LICENSE).
