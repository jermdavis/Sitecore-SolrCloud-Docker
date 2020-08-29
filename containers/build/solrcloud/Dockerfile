# escape=`

ARG BASE_IMAGE

FROM ${BASE_IMAGE}

#
# Bit of a hack for content-schema
# It should generate the config internally - but using
# PowerShell to compress the zip doesn't work
#

RUN New-Item -Path 'C:\\cloud' -ItemType Directory | Out-Null;

COPY StartCloud.ps1 C:\Cloud
COPY MakeCollections.ps1 C:\Cloud
COPY Sitecore.zip C:\Cloud
COPY Xdb.zip C:\Cloud
COPY Collections.txt C:\Cloud

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

