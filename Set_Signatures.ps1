﻿#determine the assessment folder based of where this is executed from; you can also explicitly define it here
$directoryPath = Split-Path $MyInvocation.MyCommand.Path
cd $directoryPath

#check if cert exists already
$certCheckMy = (Get-Childitem cert:\CurrentUser\My | Where-Object { $_.subject -like '*Powershell_Assessments*' }).Thumbprint
$certCheckRoot = (Get-Childitem cert:\CurrentUser\Root | Where-Object { $_.subject -like '*Powershell_Assessments*' }).Thumbprint
$certCheckPub = (Get-Childitem cert:\CurrentUser\TrustedPublisher | Where-Object { $_.subject -like '*Powershell_Assessments*' }).Thumbprint

#delete cert if exists
if(test-path -path Cert:\CurrentUser\My\$certCheckMy)
{
    Remove-Item -Path Cert:\CurrentUser\My\$certCheckMy -confirm  -Recurse
}

if(test-path -path Cert:\CurrentUser\TrustedPublisher\$certCheckPub)
{
    Remove-Item -Path Cert:\CurrentUser\TrustedPublisher\$certCheckPub -confirm -Recurse
}

if(test-path -path Cert:\CurrentUser\Root\$certCheckRoot)
{
    Remove-Item -Path Cert:\CurrentUser\Root\$certCheckRoot -confirm -Recurse
}

if(test-path PS_ASSESSMENT_CERT.crt)
{
    Remove-Item -Path PS_ASSESSMENT_CERT.crt
}


#create cert
New-SelfSignedCertificate -subject "Powershell_Assessments" -CertStoreLocation Cert:\CurrentUser\My\ -Type Codesigning

#move to trusted root
Export-Certificate -Cert (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0] -FilePath PS_ASSESSMENT_CERT.crt
Import-Certificate -FilePath PS_ASSESSMENT_CERT.crt -Cert Cert:\CurrentUser\TrustedPublisher
Import-Certificate -FilePath PS_ASSESSMENT_CERT.crt -Cert Cert:\CurrentUser\Root


#check if cert exists already
$certCheckMy = (Get-Childitem cert:\CurrentUser\My | Where-Object { $_.subject -like '*Powershell_Assessments*' }).Thumbprint
$certCheckRoot = (Get-Childitem cert:\CurrentUser\Root | Where-Object { $_.subject -like '*Powershell_Assessments*' }).Thumbprint
$certCheckPub = (Get-Childitem cert:\CurrentUser\TrustedPublisher | Where-Object { $_.subject -like '*Powershell_Assessments*' }).Thumbprint

#find files to sign
$files = gci | Where-Object { !$PsIsContainer -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -match "Powershell_Assessment_Compile" -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -notmatch "retry"}

#sign compile scripts
foreach($compile in $files){

    Set-AuthenticodeSignature -FilePath $compile.FullName -Certificate (Get-ChildItem -Path Cert:\CurrentUser\My\$certCheckMy -CodeSigningCert)[0]

    $Signature = Get-AuthenticodeSignature $compile.FullName
    $Signature.StatusMessage
}

