# LEAP Legal Software Repair Script

Quickly do a **complete** reinstall of the LEAP Legal Software on the fly, with a 1 liner in PowerShell
<hr />
LEAP Legal Software has an uncanny ability to break, to the point where a typical reinstall will not resolve it. Having had this issue too many times to count, and the typical full reinstallation processing taking ~30 minutes / PC, I decided to script it.<br>
This full reinstallation package fixing the majority of common issues and will save you hours of queue time waiting for a tech who's first task will be to do exactly this.<br/>
I've managed to get a full reinstall down to roughly 3 minutes now, saving a ton of time.

## What does it fix?
This script simply completely removes all traces of LEAP from a system before downloading and running the installer. It's not completely quiet and requires the user to select Next on the installer and handful of times.<br>
Has been tested extensively, and is known to fix the following issues we encountered;
- LEAP splash screen / login not showing up (unable to open LEAP)
- Error setting local data folder
- Communication problems with Outlook/Word
- Random communication with LEAP server errors
- Unable to open Emails, Documents and Spreadsheets from LEAP due to addin errors
- Print to LEAP function not working

## Run the script
If you have no plans on self hosting this script, or want to run it as a once off, you can run the most up to date version of this script copy and pasting the below command into an admin Powershell session, or by downloading ```LEAP-AIO.ps1``` and running it directly off the machine.<br/><br/>
```irm https://raw.githubusercontent.com/Hebbins/LEAP-Fix/refs/heads/main/LEAP-AIO.ps1 | iex```

## Self Hosting (MSP / Internal IP Departments)
Self host the `fetch.php` file somewhere accessible.<br/>
Open PowerShell and run the following command to run it: ```irm https://your-site/fetch.php```<br/>
Bonus points, you can setup a subdomain and point it to an empty folder, and rename `fetch.php` to ```index.php``` so all you need to do is run ```irm https://subdomain.site.tld | iex```


## Credits
[Bigbozza](https://github.com/bigbozza)<br>
[Hebbins](https://github.com/hebbins)
