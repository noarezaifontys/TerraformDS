# Viewing ELK Logs via the Azure CLI

Use the Azure CLI to list, download and inspect your Elasticsearch, Kibana and Logstash files stored in Azure Files.

---

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) installed  
- You are signed in:  
  ```bash
  az login
  
  az account set --subscription <YOUR_SUBSCRIPTION_ID>

---

## 1. Identify the Storage Account

RESOURCE_GROUP="MC_Dataplatform-Group-Monitoring_my-aks-cluster_westeurope"
STORAGE_ACCOUNT=$(az storage account list \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" -o tsv)
echo "Storage account: $STORAGE_ACCOUNT"

---

## 2. List All File Shares
az storage share list \
  --account-name $STORAGE_ACCOUNT \
  -o table

You should see shares like:

pvc-1697cf51-77ed-4d17-91c1-5001c5207806
pvc-1d56d97a-8d17-4cef-86bb-02328d030abb
pvc-874ecb9a-2cd1-4eec-92b8-93bbde56c400

---

## 3. List Contents of a Specific Share
Logs Share:

az storage file list \
  --account-name $STORAGE_ACCOUNT \
  --share-name pvc-1d56d97a-8d17-4cef-86bb-02328d030abb \
  -o table

or

Data share:

az storage file list \
  --account-name $STORAGE_ACCOUNT \
  --share-name pvc-1697cf51-77ed-4d17-91c1-5001c5207806 \
  -o table

---

az storage file download \
  --account-name $STORAGE_ACCOUNT \
  --share-name pvc-1d56d97a-8d17-4cef-86bb-02328d030abb \
  --path gc.log.00 \
  --dest ./gc.log.00 \
  --auth-mode login


---
## 4. Download or View a File
Download to Local Disk:

az storage file download \
  --account-name $STORAGE_ACCOUNT \
  --share-name pvc-1d56d97a-8d17-4cef-86bb-02328d030abb \
  --path gc.log.00 \
  --dest ./gc.log.00 \

or

Stream Directly to Terminal
az storage file download \
  --account-name $STORAGE_ACCOUNT \
  --share-name pvc-1d56d97a-8d17-4cef-86bb-02328d030abb \
  --path gc.log.00 \
  --dest - \

---

## File Share → Contents Mapping:

| File Share       | Type               | Example Contents                          |
| ---------------- | ------------------ | ----------------------------------------- |
| **elk-logs-pvc** | Log files          | `gc.log`, `gc.log.00`, etc.               |
| **elk-data-pvc** | Elasticsearch data | `nodes/`, `_state/`, `.lock`, …           |
| **elk-pvc**      | Combined (legacy)  | Both logs and data from older deployments |




