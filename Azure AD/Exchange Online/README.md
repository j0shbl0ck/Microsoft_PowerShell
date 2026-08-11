# 📂 Exchange Online

PowerShell scripts for day-to-day and bulk administration of Exchange Online — mailboxes, distribution lists, contacts, calendar permissions, compliance/retention, mail security, and reporting. Most scripts connect interactively via `Connect-ExchangeOnline` (some use the Microsoft Graph PowerShell SDK) and prompt for the objects they act on, so they can be run ad hoc against a tenant without editing variables first.

<p>
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white" alt="PowerShell 5.1+"/>
  <img src="https://img.shields.io/badge/Folders-13-blue" alt="13 Folders"/>
  <img src="https://img.shields.io/badge/Scripts-50%2B-informational" alt="50+ Scripts"/>
  <img src="https://img.shields.io/badge/Author-j0shbl0ck-black?logo=github" alt="Author"/>
</p>

> ⚠️ **Before you run anything:** a few scripts below are early drafts, working notes, or reference snippets rather than finished tools — they're tagged **🚧 WIP** in their tables. Everything else is tagged **✅ Ready**, but several scripts make bulk, tenant-wide changes — always test in a non-production tenant/account first.

Click a folder to jump straight to it 👇

<table>
<tr>
<td width="33%">

📇 [Address List](#-address-list)
📅 [Bookings](#-bookings)
🗄️ [Compliance & Rentention](#️-compliance--rentention)
👥 [Contact Management](#-contact-management)
📬 [Distribution List](#-distribution-list)

</td>
<td width="33%">

🛡️ [Mail Security](#️-mail-security)
🔐 [Mail-enabled Security](#-mail-enabled-security)
📥 [Mailbox Management](#-mailbox-management)
📱 [Mobile & Apps](#-mobile--apps)

</td>
<td width="33%">

📍 [Places](#-places)
♻️ [Restore Mailbox](#-restore-mailbox)
🔀 [Rules & Mail Flow](#-rules--mail-flow)
🧪 [Testing & Tools](#-testing--tools)

</td>
</tr>
</table>

---

## 📇 Address List

<details open>
<summary><strong>1 item</strong> — Address List / Address Book Policy reference</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| 🚧 | `al_notes.ps1` | Reference commands (not a runnable script) for creating/updating/removing Address Lists and Address Book Policies, and assigning an ABP to a mailbox. |

</details>

## 📅 Bookings

<details open>
<summary><strong>1 item</strong> — Microsoft Bookings lookups</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| 🚧 | `Get-Booking-Members.ps1` | Connects via an Entra app registration (client credential flow) with Microsoft Graph to pull Bookings-related membership info. |

</details>

## 🗄️ Compliance & Rentention

<details open>
<summary><strong>8 items</strong> — archiving, retention holds/policies, mailbox size reporting</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Enable_Online_Archive.ps1` | Enables the Online Archive for a mailbox and kicks off the Managed Folder Assistant to force archiving to begin immediately. |
| ✅ | `Move_Deleted_Items.ps1` | Creates a sweep (Inbox) rule that moves messages from one folder to another on a schedule. |
| ✅ | `disable_retent_hold.ps1` | Turns off Retention Hold on a mailbox (or all mailboxes via menu) so retention/MRM policies can process normally. |
| ✅ | `enable_mailbox_archive.ps1` | Enables mailbox archiving for a specific user or org-wide via an interactive menu. |
| ✅ | `enable_retent_plcy.ps1` | Assigns/enables a retention policy on a mailbox (or all mailboxes via menu). |
| ✅ | `get-all-mailbox-size.ps1` | Reports total mailbox size across every mailbox in the tenant. |
| ✅ | `get-mailbox-size.ps1` | Reports the top 10 largest folders across a mailbox's Primary, Recoverable Items, and Archive locations. |
| ✅ | `manage_folderassist.ps1` | One-line troubleshooting reference for checking Managed Folder Assistant / ELC processing status and clearing `RetentionHoldEnabled`. |

</details>

## 👥 Contact Management

<details open>
<summary><strong>3 items</strong> — bulk import, custom RBAC roles, cleanup</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Bulk_Contact_Import/Bulk_Contact_Import.ps1` | Imports mail contacts in bulk from a CSV file (sample `contact_list.csv` included). |
| ✅ | `Contact_Admin_Roles.ps1` | Creates two custom RBAC roles ("Contact Creator" and "Contact Modifier") for assignment to a role group like Help Desk. |
| 🚧 | `Remove_All_Contacts.ps1` | Graph-based snippets for locating and deleting contacts across the tenant by domain/email match. |

</details>

## 📬 Distribution List

<details open>
<summary><strong>8 items</strong> — create, import, export, rebuild, audit</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Add_Members_Distrubtion_List_CSV.ps1` | Imports members from a CSV (`WorkEmail` column) into a single specified cloud distribution list, skipping existing members. |
| ✅ | `All_Company_Distribution_List.ps1` | Builds an "all company" distribution list from every licensed, non-shared, non-external user. |
| ✅ | `Bulk_DL_Import/Bulk_DL_Import.ps1` | Creates multiple distribution lists in bulk from a CSV (sample `distro_lists.csv` included). |
| ✅ | `Bulk_Owner_Distribution_List.ps1` | Bulk-assigns owners to distribution lists. |
| ✅ | `Distribution_Member_Export.ps1` | Exports the membership of a given distribution list to CSV. |
| ✅ | `Export_Rebuild_Distribution_List.ps1` | Captures a full DL configuration (addresses, owners, members, delivery/moderation/visibility settings) to CSV and generates a standalone script to recreate the group. |
| ✅ | `Send_As_Delegate_DL.ps1` | Grants Send As permission on a distribution list to a specified user. |
| ✅ | `User_Distribution_Membership.ps1` | Looks up all distribution groups and mail-enabled security groups a given user belongs to. |

</details>

## 🛡️ Mail Security

<details open>
<summary><strong>6 items</strong> — safe senders, external mail tagging, device quarantine</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Safe Senders/All_Add_Safe_Senders.ps1` | Adds a specified domain/address to **every** user's Safe Senders list. |
| ✅ | `Safe Senders/Indv_Add_Safe_Sender.ps1` | Adds a specified domain/address to a single user's Safe Senders list. |
| ✅ | `Security & External Mail/allow-quaran-device.ps1` | Releases a user's quarantined ActiveSync devices, restoring mobile mail access. |
| ✅ | `Security & External Mail/block-sharedmailbox-signin.ps1` | Blocks sign-in on a shared mailbox account. |
| ✅ | `Security & External Mail/set-external-mail-tag.ps1` | Enables or disables the external sender mail tag tenant-wide. |
| ✅ | `Security & External Mail/set-external-mail-warning.ps1` | Creates the mail flow rule/disclaimer that auto-tags inbound external messages with a warning banner. |

</details>

## 🔐 Mail-enabled Security

<details open>
<summary><strong>2 items</strong> — group membership and send permissions</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `MES_User_Import.ps1` | Bulk-imports users from a CSV into a mail-enabled security group. |
| ✅ | `Send_To_ME_Groups.ps1` | Updates who is permitted to send to a mail-enabled security group. |

</details>

## 📥 Mailbox Management

<details open>
<summary><strong>17 items</strong> — permissions, calendars, folders, addresses</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Calendar Permissions/Bulk_Calendar_Rights.ps1` | Bulk-assigns calendar permissions (e.g., PublishingAuthor on a shared mailbox calendar) to a list of users via CSV. |
| ✅ | `Calendar Permissions/Change_Calendar_Rights.ps1` | Interactively sets one user's calendar permission level on another user's calendar. |
| ✅ | `Calendar Permissions/New-FullCalendarMesh.ps1` | Uses Microsoft Graph to grant every licensed user Editor access to every other licensed user's calendar, building a fully-connected permission mesh with validation. |
| ✅ | `Calendar Permissions/Set-DefaultCalendarPermission/` | Graph-based script (with its own [README](Mailbox%20Management/Calendar%20Permissions/Set-DefaultCalendarPermission/README.md) and app-registration walkthrough) that sets every licensed user's default calendar "My Organization" permission to Write, tenant-wide. |
| ✅ | `Calendar Permissions/View_Calendar_Rights.ps1` | Views the current calendar permissions on a specified mailbox. |
| ✅ | `Client Access/get_mailbox_access.ps1` | Grants a user Full Access to a mailbox without assigning a license. |
| ✅ | `Client Access/copy-mailbox-permissions` | Compares and syncs Full Access / Send As permissions between a source and target shared mailbox, removing mismatches and summarizing the result. |
| ✅ | `Folder Permissions/root-folder-access.ps1` | Grants Owner permissions to a target user on every subfolder beneath a specified mailbox folder. |
| ✅ | `Folder Permissions/set-folder-permissions.ps1` | Updated/parameterized version of the root folder access script for granting Owner permissions across subfolders. |
| ✅ | `Mailbox Group Info/User_Microsoft365_Membership.ps1` | Looks up which Microsoft 365 (unified) groups a user belongs to. |
| ✅ | `Mailbox Group Info/Verify_Email_Identitify.ps1` | Displays the recipient type/identity details for a given mailbox. |
| ✅ | `bulk-add-shared-mailbox.ps1` | Bulk-grants a user Full Access and Send As permissions across a predefined list of shared mailboxes. |
| ✅ | `disable-automapping-access.ps1` | Disables Outlook automapping for a shared mailbox by removing and re-adding Full Access and Send As rights for a delegate. |
| ✅ | `get-automatic-reply.ps1` | Checks a mailbox's automatic reply (out-of-office) configuration and optionally clears it. |
| ✅ | `get-mailbox-permissions.ps1` | Interactively looks up Full Access permissions on a mailbox, resolving trustee display names. |
| ✅ | `remove-cloud-mailbox.ps1` | Removes cloud mailboxes for a user (bulk-capable via file selection). |
| ✅ | `update-mailbox-emailaddresses.ps1` | Views and adds/removes SMTP email addresses on a mailbox. |

</details>

## 📱 Mobile & Apps

<details open>
<summary><strong>2 items</strong> — integrated apps and mobile device reporting</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `get-integrated-apps.ps1` | Lists all integrated (add-in) apps registered in Exchange Online. |
| ✅ | `get-outlookmobile-info.ps1` | Reports on users accessing mail via mobile, including the device/app in use. |

</details>

## 📍 Places

<details open>
<summary><strong>1 item</strong> — Places Finder group lookups</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Get-Places-Groups.ps1` | Looks up the group(s) scoped in Microsoft Places Finder settings, resolving object IDs to distribution group display names. |

</details>

## ♻️ Restore Mailbox

<details open>
<summary><strong>2 items</strong> — Recoverable Items / Archive restoration</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `Archive_Folder_Audit.ps1` | Audits archive mailbox folders for a given naming pattern (e.g., "Restored at...") and totals matching messages. |
| 🚧 | `Restore_Archive_Deleted.ps1` | Reference commands for locating a mailbox's Archive GUID and restoring items from Recoverable Items. |

</details>

## 🔀 Rules & Mail Flow

<details open>
<summary><strong>1 item</strong> — inbox rule auditing</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `get-mailbox-inboxrules.ps1` | Lists all Inbox rules for a mailbox, including hidden and Microsoft built-in rules. |

</details>

## 🧪 Testing & Tools

<details open>
<summary><strong>2 items</strong> — SMTP connectivity and relay testing</summary>

| Status | Script | Description |
| :---: | --- | :--- |
| ✅ | `test-smtp-mx.ps1` | Tests SMTP connectivity on port 25 and sends a sample phishing-style test email for security awareness/testing purposes. |
| ✅ | `test-smtp-send.ps1` | Tests SMTP relay/submission on port 587 with basic authentication. |

</details>

---

## 🔧 Requirements

- [ExchangeOnlineManagement](https://www.powershellgallery.com/packages/ExchangeOnlineManagement) module
- [Microsoft Graph PowerShell SDK](https://www.powershellgallery.com/packages/Microsoft.Graph) — for Graph-based scripts (calendar mesh, Bookings, contact removal)
- Global Admin / Exchange Admin (or an appropriately scoped custom RBAC role) for the tenant being managed

## ⚠️ Notes on Use

- Scripts that loop over **all mailboxes/users** (e.g., `All_Company_Distribution_List.ps1`, `All_Add_Safe_Senders.ps1`, `New-FullCalendarMesh.ps1`, `Set-DefaultCalendarPermission.ps1`) make tenant-wide changes — test against a pilot group first where possible.
- Placeholder tenant IDs, client secrets, and sample email addresses (`domain.com`, `contoso.com`, `xxxxxx`) throughout these scripts need to be replaced with your own values before use.
- 🚧 **WIP** scripts are not polished, end-to-end tools — treat them as a starting point or command reference rather than something to run as-is.
