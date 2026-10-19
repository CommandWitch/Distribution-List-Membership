# ?? Distribution Group Bulk Membership Tool

Add or remove users to Exchange Distribution Lists (DLs) — **either in bulk via CSV OR individually** — no manual Exchange Admin Centre needed.

---

## ? Quick Start

1. Save your file (CSV, or nothing needed for manual entry).
2. Run [.\Add or Remove CSV or Manual.ps1]
3. Sign in with your ADM account when prompted
4. Follow the on-screen steps

--

## ?? Two Ways to Add/Remove Members

### Option 1: Bulk CSV Upload (Best for 4+ people)
- Prepare a CSV file with **one column named exactly `EmailAddress`** 
- Example (see example files):
 EmailAddress
 john.doe@hachette.co.uk
 jane.smith@hachette.co.uk

- Save to **Server Desktop**
- When prompted ? choose **1** ? browse and select your file

### Option 2: Manual Entry (Best for 1–3 people)
- When prompted ? choose **2**
- Type email addresses one at a time
- Leave blank + press **Enter** when done

---

## ??? Full Workflow

| Step | What Happens |
|---|---|
| 1. Choose Action | Type `ADD` or `REMOVE` |
| 2. Choose Input | `1` = CSV file, `2` = type emails manually |
| 3. Sign In | Browser window opens ? use your work account |
| 4. Select DL(s) | A list pops up ? tick one or more DLs ? OK |
| 5. Confirm | Script runs and shows: ? Added / ?? Already member / ? Failed |
| 6. Logs Saved | Results saved to: `Desktop\DL-Membership-Logs\` |

---

## ?? Finding Your Results
- Logs are **always saved to your Desktop** in a folder called:
  DL-Membership-Logs
  +- DL-Details-ADD-20260923-153022.csv
  +- DL-Summary-ADD-20260923-153022.csv
- Filenames include **date + time** so nothing gets overwritten

---

## ?? Common Messages

| Message | Meaning |
|---|---|
| already member | Email is already on that DL — no action needed |
| not member | Email wasn't there (for REMOVE) — no action needed |
| Failed: [error] | Couldn't update — check spelling or ask IT |

---

## ?? Getting the Latest Version
New versions appear here in Azure DevOps. To update your server copy:
1. Click the `.ps1` file in this repo
2. Click **Download** ??
3. Save to: `C:\DSS_SharedScripts\`
4. Overwrite when prompted ?

---

## ?? Tips
- ? You can select **multiple DLs at once** — same emails go to all
- ? Duplicate emails are automatically removed
- ? All warnings are hidden — screen stays clean
- ? Works from the server or your desktop
- ? Do **not** edit the script while running it — save first, run second

---

## ?? Help & Support
This script maintained in an Azure DevOps repo. Contact Linda.Alexis@hachette.co.uk
