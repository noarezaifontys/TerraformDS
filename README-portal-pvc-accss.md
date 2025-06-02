# Viewing ELK Logs via the Azure Portal

This guide shows you how to browse your Elasticsearch, Kibana and Logstash files (data & logs) in Azure Files directly from the Azure Portal.

---

## 1. Sign in & Locate the MC_* Resource Group

1. Go to the [Azure Portal](https://portal.azure.com) and sign in.  
2. In the left-hand menu, click **Resource groups**.  
3. Find and open the resource group named:  


---

## 2. View Kubernetes Storage

1. In that MC_… resource group, scroll down to **Kubernetes resources** and select **Storage**.  
2. Switch to the **Persistent volume claims** tab. You will see your claims in the `default` namespace:
- `elk-pvc`  
- `elk-data-pvc`  
- `elk-logs-pvc`  

---

## 3. Find the Underlying File Share

1. Still in the **Storage** blade, go to **Persistent volumes**.  
2. Click the volume whose **Claim name** matches your PVC (e.g. `pvc-1697cf51…`).  
3. In the volume details, note the **Storage account** name and click it.  
4. In that Storage Account’s menu, type intot he bar **File shares**.  

You will now see one or more shares with these kind of strings (these change on every redeploy):
- `pvc-1697cf51-77ed-4d17-91c1-5001c5207806`  
- `pvc-1d56d97a-8d17-4cef-86bb-02328d030abb`  
- `pvc-874ecb9a-2cd1-4eec-92b8-93bbde56c400`  

---

## 4. Browse Files in Each Share
click on "browse" in the left column and view the contents

---

## the contents per PVC

Click a share to drill into its folders and files:

| File Share (PVC)       | Share Name (pvc-…)                            | Contains                                                     |
|------------------------|-----------------------------------------------|--------------------------------------------------------------|
| **elk-data-pvc**       | pvc-1697cf51-77ed-4d17-91c1-5001c5207806       | Elasticsearch data directories (e.g. `nodes/`, `_state/`)   |
| **elk-logs-pvc**       | pvc-1d56d97a-8d17-4cef-86bb-02328d030abb       | Log files (`gc.log`, `gc.log.00`, etc.)                      |
| **elk-pvc**            | pvc-874ecb9a-2cd1-4eec-92b8-93bbde56c400       | Legacy combined share (data + logs from older deployments)   |

> **Tip:** Click any file to preview its contents in the portal, or download it for deeper inspection.
