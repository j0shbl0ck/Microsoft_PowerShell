# ⚡ Microsoft PowerShell Toolkit

A curated collection of PowerShell scripts to manage Microsoft environments — including **tenants**, **mailboxes**, **users**, **groups**, and more.

> 🧪 All scripts are provided _as-is_. Test in a controlled environment before deploying to production.

---

## 🗂 Folder Overview

This repository is organized by functional areas for easy discovery and use:

| 📁 **Folder**       | 📜 **Description**                                                                 |
|---------------------|------------------------------------------------------------------------------------|
| `Active Directory`  | Scripts for managing **on-prem AD** attributes and handling **AAD Connect** tasks. 🔧 |
| `Azure AD`          | Tools for working with **Exchange Online**, **SharePoint Online**, and Azure identities. 🔒 |
| `Entra ID`          | Scripts using legacy **Entra ID** cmdlets. ⚠️ _(Superseded by modern AzureAD modules)_ |
| `Scripts`           | Helpers for installing and managing **Microsoft 365 PowerShell modules**. 🔄 |
| `System`            | System-focused scripts, including **RMM automation**, **security hardening**, and OS tasks. 🛡 |

---

## 📌 Script Standards

Each script follows a clean, consistent format:

- **Filename Format**: `verb-action-target.ps1`  
  _Example: `set-password-expiration.ps1`_

- **Header Block**:
  ```powershell
  <#
  .SYNOPSIS     Short description of the script
  .NOTES        Contains Author, Date, Type, Version, and Links
  .LINK         Relevant links for further information
  #>
