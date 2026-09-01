# Set-DefaultCalendarPermission.ps1

This PowerShell script creates a fully connected internal calendar sharing mesh in Microsoft 365 by setting each licensed user's **default calendar** permission for **"My Organization"** to `"write"`. This enables all users in your tenant to **view and edit** each other's calendars without needing to manually share. *Users will need to search and add the other users' calendars to their Outlook client or web app, but once added, they will have full access.*

---

## ✅ Features

- Uses **Microsoft Graph PowerShell SDK** (Application Permissions)
- Automatically discovers all **licensed** users in the tenant
- Grants `"write"` access to **"My Organization"** on each user’s default calendar
- Logs success and any errors per user
- Validates that the `"My Organization"` role is properly assigned after execution
- Automatically installs or updates the Graph module if required
- Auto-detects if not running as admin and warns appropriately

---

## 📋 App Registration & Permission Setup

To use this script, you must register an Azure AD application and grant it Microsoft Graph API permissions.

### Step 1 – Create New App Registration

- Navigate to: [Entra Portal – Applications - App registrations](https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
- Click **"New registration"**
- Set a meaningful name (e.g., `CalendarMeshApp`)

### Step 2 – Set Account Types

Choose: **Accounts in this organizational directory only ({company} only - Single tenant)**

### Step 3 – Add Redirect URI

Under **Redirect URI**:
- Platform: `Public client/native`
- URI: http://localhost

### Step 4 – Add Microsoft Graph API Permissions

Under **API permissions**, click **Add a permission** → **Microsoft Graph** → **Application permissions**, then add:

- `Calendars.ReadWrite`
- `User.Read.All`

Click **“Grant admin consent”** to approve the permissions.

#### 🔒 Legacy Permissions (NO LONGER NEEDED – only for early testing)

If these exist in your app, they can be removed:

- `Application.ReadWrite`
- `Mail.ReadWrite`
- `MailFolder.ReadWrite`
- `MailSettings.ReadWrite`
- `User.ReadWrite`

### Step 5 – Generate a Client Secret

Go to **Certificates & secrets > New client secret**.

- Choose a name and expiration period
- After saving, **copy the secret VALUE** immediately

### Step 6 – Collect Required App Details

You’ll need the following:

- **Application (Client) ID**
- **Directory (Tenant) ID**
- **Client Secret Value**

### Step 7 – Modify the Script

Open `New-FullCalendarMesh.ps1` and edit lines 24–26:

```powershell
param (
    [string]$ClientId     = "<your-client-id>",
    [string]$TenantId     = "<your-tenant-id>",
    [string]$ClientSecret = "<your-client-secret>"
)
```
Optional: Review line 130 or anywhere the role "write" is specified, in case you prefer a different permission level.

```powershell
Update-MgUserCalendarPermission -UserId $user -CalendarId $calendarId -CalendarPermissionId $permId -BodyParameter @{
    Role = "write"
} | Out-Null
```

Reference for roles: [Calendar Permissions – Microsoft Docs](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.calendar/update-mggroupcalendarpermission?view=graph-powershell-1.0#notes)




