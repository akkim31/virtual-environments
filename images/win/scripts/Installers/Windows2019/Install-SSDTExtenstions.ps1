###################################################################################
##  File:  Install-SSDTExtensions.ps1
##  Desc:  Install the extensions previously known as SSDT package
###################################################################################

Import-Module -Name ImageHelpers -Force

Install-VsixExtension -Url 'https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ProBITools/vsextensions/MicrosoftAnalysisServicesModelingProjects/2.9.5/vspackage' -Name 'Microsoft.DataTools.AnalysisServices.vsix'
Install-VsixExtension -Url 'https://marketplace.visualstudio.com/_apis/public/gallery/publishers/SSIS/vsextensions/SqlServerIntegrationServicesProjects/3.4/vspackage' -Name 'Microsoft.DataTools.IntegrationServices.vsix'
Install-VsixExtension -Url 'https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ProBITools/vsextensions/MicrosoftReportProjectsforVisualStudio/2.6.3/vspackage' -Name 'Microsoft.DataTools.AnalysisServices.vsix'
