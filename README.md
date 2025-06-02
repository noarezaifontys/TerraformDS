
# ELK Monitoring Platform on Azure (AKS + Fleet Server)

This repository contains a complete setup for a scalable ELK stack on Azure, including:  
- AKS cluster  
- Fleet Server & Agent VMs  
- Elasticsearch, Kibana, and Logstash  
- Automation via Terraform  
- Scripts to retrieve sensitive tokens/credentials  

---

## ⚙️ Requirements

- Azure Subscription  
- Terraform  
- Azure CLI  
- Git Bash or WSL (for Bash scripts)  
- Ports 5601, 8220, 9200, 5044 open in the NSG  
- OpenSSH (for SSH access to VMs)  

---

## ✏️ Step 1 – Preparation

### ✅ Visual Studio Code Configuration

#### Step 1:
Open Visual Studio Code in the folder where `main.tf` is located. Switch the terminal to **Git Bash**.

#### Step 2:
Log in using Azure CLI:

```bash
az login
```

Do you have multiple subscriptions? Select the correct one via:

```bash
az account set --subscription "Subscription-ID-or-Name"
```

#### Step 3:
Clone the repository:

```bash
git clone https://github.com/sekariyad2000/elkstack-terraform
```

---

## ☁️ Step 2 – Deploy Infrastructure

1. Open a **Git Bash terminal** in the folder where `main.tf` is located.  
2. Retrieve your Subscription ID with:

```bash
az account show --output json
```

📋 Copy the `id` value and save it temporarily.

3. Start the Terraform setup:

```bash
terraform init
terraform plan
terraform apply
```

During `terraform apply`, you’ll be asked for your subscription ID:

📸 See:  
> var.subscription_id  
> Azure Subscription ID (prompted during execution)  
> Enter a value:

Enter your copied ID. Confirm with `yes`. This will take about **6–8 minutes**.

✅ This will create:  
- AKS cluster  
- Fleet & Agent VMs  
- VNet, IPs, subnets, NSG  
- ELK stack on Kubernetes  

---

## 🔐 Step 3 – Retrieve Sensitive Credentials

After running `terraform apply`, Terraform will attempt to automatically retrieve the following credentials:

- **Kibana Verification Code**  
- **Elasticsearch Password**  
- **Enrollment Token**

These should appear in the Terraform output at the end of the deployment.

### ⚠️ Didn't see them?

If any of the credentials are missing or show an error like `"ERROR: ..."` in the output, you can manually retrieve them by running the following scripts from the root folder of this project:

```bash
bash elastic-password.sh
bash elastic-enrollment-token.sh
bash kibana-verification-code.sh
```

---

## 🌐 Step 4 – Access Kibana via Azure

1. Go to Azure Portal → resource group `Dataplatform-Group-Monitoring`  
2. Open the AKS cluster → Services  
3. Find `kibana` → copy the **external IP**  
4. Open it in your browser and follow the setup  

---

## 🛰️ Step 5 – Install Fleet Server

In this step, we install the **Fleet Server** on the Fleet VM. The Fleet Server manages all connected Elastic Agents and ensures that logs, metrics, and other data are collected and forwarded to Elasticsearch. This is the core of the monitoring architecture.

1. In Kibana, go to **Fleet**  
2. Click **Add Fleet Server**  
3. Enter the **IP of the Fleet VM**  
4. Copy the generated script  

SSH into the Fleet VM:

```bash
ssh -i ssh/fleet_vm_id_rsa azureuser@<Fleet-VM-IP>
sudo apt update && sudo apt upgrade -y
```

Then paste the full installation command into the terminal

ℹ️ **Note:**  
- If installation is interrupted, append `&&` at the end of each command line.  
- If a previous installation exists, uninstall it first with:

```bash
sudo /opt/Elastic/Agent/elastic-agent uninstall
```

---

## 🤖 Step 6 – Install Agent on Agent VM

1. In Kibana, click **Add agent**  
2. Enter the IP of the Fleet VM again  
3. Add **--insecure** at the end of the script  
4. SSH into the Agent VM:

```bash
ssh -i ssh/agent_vm_id_rsa azureuser@<Agent-VM-IP>
sudo apt update && sudo apt upgrade -y
# paste the script with --insecure here
```

---

## 📊 Step 7 – Expand Monitoring

Use the search bar in Kibana to activate integrations like:
- Azure Monitoring  
- Kubernetes Metrics  
- Azure Activity Logs  

---

## 📁 Project Structure

```
ELKSTACK-TERRAFORM/
├── elastic-enrollment-token.sh
├── elastic-password.sh
├── kibana-verification-code.sh
├── LICENSE
├── main.tf
├── variables.tf
├── README.md
```

---

## ✅ Ready to Use

Your platform is now ready! You can easily onboard new projects by:
- Deploying a new namespace + elastic-agent  
- Logs/metrics are automatically collected via Fleet  

---

## ✍️ Author

Created for a project based on a research assignment on monitoring.
