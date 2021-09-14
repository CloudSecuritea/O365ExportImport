# O365ExportImport
# https://www.cloudsecuritea.com/2021/09/export-import-of-office-365-and-azure-configuration/

In two weeks I’ll be starting at a new company as an Information Security specialist. In order to prepare for this new endeavor I’ll be updating my developer tenant for testing purposes. All best practices I know and found on the internet will be added to the configuration. I want to configure for example Teams, SharePoint, Endpoint, MCAS and Microsoft Information Protection. Developer tenants are auto renewable every 120 days if there has been activity detected on the tenant. The next couple of blogs will be focused on exporting and importing configuration settings using PowerShell so I can get quickly up and running again should my developer tenant expire. For each topic I’ll create a new post. The PowerShell scripts and configs will be stored in GitHub. Bare with me as content will be updated when ready.

Exporting & Importing topics

This is the first blog which will outline my ambition to create a post for the below topics. I’m not yet sure if all best practices and configurations are PowerShell/Graph ready but I’ll learn that on the way.

Azure Active Directory
Azure Active Directory Identity Protection
Security Center
Compliance Center
SharePoint & OneDrive
Teams
Exchange
Endpoint (Intune)
Stream
Conditional Access
Office 365 General
Power BI
Yammer
Defender for Endpoint
Defender for Office 365
Microsoft Cloud App Security
Microsoft Information Protection
Microsoft 365 developer program

I was contemplating adding one Microsoft 365 E5 license for testing and updating the configuration for my personal tenant. A Microsoft 365 developer subscription doesn’t have Defender for Endpoint and I really want that functionality in my test environment. I decided to add the Defender for Endpoint add-on to the developer tenant as a trial which is active for 3 months. The developer tenant also has 25 licenses which will make testing easier between users. I’ve created my developer tenant the first moment we were able to create an E5 tenant as it was E3 previously and I’ve got 68 days remaining until Microsoft will verify my activity and decide if I can use it for 120 more days. Interested in a Microsoft 365 E5 tenant to test your solutions for the Microsoft 365 platform? Go to Developer Program - Microsoft 365 and join now with your personal Outlook account or a business account.