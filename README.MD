# Global Azure Bootcamp 2017 session source files
This repository contains files used for session Devops - ARM, PESTER, GIT, DSC... czyli od czego zacząć? on Global Azure Bootcamp 2017.

The main template stored in azuredeploy.json file deploys SCCM in Azure IaaS VMs environment. IMPORTANT: The template reports that the deployment fails on SCCM DSC extension step. But it's due to the changes that SCCM setup does to WMI (and DSC relies upon WMI). SCCM setup continues and finishes successfully after approximately 30-40 minutes.
