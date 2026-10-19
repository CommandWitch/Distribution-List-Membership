\## ? Distribution Group Bulk Membership Tool



> Add or remove users to Exchange Distribution Lists (DLs).  No manual Exchange Admin Centre needed.



\---



\## ? Overview

This project allows analysts to add/remove members to/from DLs.  Members can be added/removed manually.

Or, if there are several members to process via CSV.



\--



\## ?? Two Ways to Add/Remove Members



\### Option 1: Bulk CSV Upload (Best for 4+ people)

\- Prepare a CSV file with \*\*one column named exactly `EmailAddress`\*\* 

\- Example (see example files):

&#x20;EmailAddress

&#x20;john.doe@hachette.co.uk

&#x20;jane.smith@hachette.co.uk



\- Save to \*\*Server Desktop\*\*

\- When prompted ? choose \*\*1\*\* ? browse and select your file



\### Option 2: Manual Entry (Best for 1 3 people)

\- When prompted ? choose \*\*2\*\*

\- Type email addresses one at a time

\- Leave blank + press \*\*Enter\*\* when done



\---



\## ??? Full Workflow



| Step | What Happens |

|---|---|

| 1. Choose Action | Type `ADD` or `REMOVE` |

| 2. Choose Input | `1` = CSV file, `2` = type emails manually |

| 3. Sign In | Browser window opens ? use your work account |

| 4. Select DL(s) | A list pops up ? tick one or more DLs ? OK |

| 5. Confirm | Script runs and shows: ? Added / ?? Already member / ? Failed |

| 6. Logs Saved | Results saved to: `Desktop\\DL-Membership-Logs\\` |



\---



\## ?? Finding Your Results

\- Logs are \*\*always saved to your Desktop\*\* in a folder called:

&#x20; DL-Membership-Logs

&#x20; +- DL-Details-ADD-20260923-153022.csv

&#x20; +- DL-Summary-ADD-20260923-153022.csv

\- Filenames include \*\*date + time\*\* so nothing gets overwritten



\---



\## ?? Common Messages



| Message | Meaning |

|---|---|

| already member | Email is already on that DL   no action needed |

| not member | Email wasn't there (for REMOVE)   no action needed |

| Failed: \[error] | Couldn't update   check spelling or ask IT |



\---



\## ?? Tips

\- ? You can select \*\*multiple DLs at once\*\*   same emails go to all

\- ? Duplicate emails are automatically removed

\- ? All warnings are hidden, screen stays clean

\- ? Works from the server or your desktop

\- ? Do \*\*not\*\* edit the script while running it save first, run second



\---



\## ?? Help \& Support

This script maintained in an Azure DevOps repo. Contact Linda.Alexis@hachette.co.uk



