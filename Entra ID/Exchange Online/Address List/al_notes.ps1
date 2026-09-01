## THESE ARE CURRENT NOTES.

New-AddressList -Name "Southeast Offices" -IncludedRecipients MailContacts -ConditionalCompany 'Bear Creek'
Set-AddressList -Identity "Southeast Offices" -IncludedRecipients MailContacts -ConditionalCompany 'Bear Creek'
Remove-AddressList -Identity "Southeast Offices"


New-AddressBookPolicy -Name "iSS Default ABP" -GlobalAddressList "\Default Global Address List" -OfflineAddressBook "\Default Offline Address Book" -RoomList "\All Rooms" -AddressLists "\All Users","\All Groups","\All Contacts", "\Public Folders"
Set-AddressBookPolicy -Identity "Bear Creek 02" -GlobalAddressList "\Default Global Address List" -OfflineAddressBook "\Default Offline Address Book" -RoomList "\All Rooms" -AddressLists "\All Users","\All Groups","\All Contacts", "\Public Folders","\Southnorth Offices"

Remove-AddressBookPolicy -Identity "Bear Creek 02"

Set-Mailbox -Identity user@domain.com -AddressBookPolicy "iSS Default ABP"
Set-Mailbox -Identity user@domain.com -AddressBookPolicy $null
