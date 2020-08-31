# escape=`

ARG BASE_IMAGE

FROM ${BASE_IMAGE}

#
# Bit of a hack for content-schema
# It should generate the config internally - but using
# PowerShell to compress the zip doesn't work
#
# See comments about 7zip vs PowerShell Compress-Archive here: https://jermdavis.wordpress.com/2020/08/31/solrcloud-with-sitecore-10/
#

RUN New-Item -Path 'C:\\cloud' -ItemType Directory | Out-Null;

COPY StartCloud.ps1 C:\Cloud
COPY MakeCollections.ps1 C:\Cloud
COPY Sitecore.zip C:\Cloud
COPY Xdb.zip C:\Cloud
COPY Collections.txt C:\Cloud

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

