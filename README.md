# Google Threat Intelligence MCP Server

A production-ready, highly optimized Model Context Protocol (MCP) server for Google Threat Intelligence (GTI) (incorporating VirusTotal and Mandiant threat analytics). This server supports both local desktop integration via `stdio` and cloud-native network deployments via Server-Sent Events (SSE), making it fully compatible with Google Cloud Run or any other container-native environment.

---

## Project Origin & Deployment Philosophy

This repository is **100% based on the official Google open-source implementation** hosted in the [google/mcp-security](https://github.com/google/mcp-security) repository. 

While the official project is designed as a broad, developer-focused, multi-tool mono-repo, **this project was created specifically to empower non-technical users, security analysts, and IT administrators** to deploy a secure, enterprise-grade Google Threat Intelligence (GTI) MCP server in minutes with zero friction.

### 🔍 How This Repository Differs from the Official Mono-Repo

| Feature / Aspect | Official Google `mcp-security` Mono-Repo | This Dedicated GTI Project |
| :--- | :--- | :--- |
| **Project Focus** | Multi-server (SCC, SecOps, SOAR, GTI) developers workspace. | **100% focused on Google Threat Intelligence (GTI)**. Completely stripped of unrelated bloat. |
| **Nesting Structure** | Nested deeply under `/server/gti` folders. | **Flattened to the root**. Clean git clone and run. |
| **Secrets Security** | Basic environment variables (risk of plaintext leak). | **Strictly Enforced Google Secret Manager**. |
| **Cloud Deployment** | Minimal developer deployment scaffolding. | **Production-ready Google Cloud Run templates**. |
| **User Onboarding** | Targeted at software developers and engineers. | **Designed for non-technical users**, complete with beginner-friendly command guides. |
| **No-Agent Verification**| Requires setting up and connecting an LLM desktop client. | **Instant, zero-agent verification** via a dynamic, automated `verify.sh` script. |

---

> [!IMPORTANT]
> **Production Security Mandate**: To ensure enterprise compliance and prevent credential leakage, this deployment **strictly requires** the use of **Google Secret Manager** to store and load your API key. Direct injection of plaintext credentials via environment variables is disabled/prohibited for cloud deployments.

---

## Table of Contents
1. [Project Origin & Deployment Philosophy](#project-origin--deployment-philosophy)
2. [Core Features](#core-features)
3. [Configuration & Customization (Optional)](#configuration--customization-optional)
4. [Local Development & Setup](#local-development--setup)
5. [Containerization & Docker](#containerization--docker)
6. [Production Google Cloud Run Deployment (Strict Secret Manager)](#production-google-cloud-run-deployment-strict-secret-manager)
7. [MCP Client Configurations](#mcp-client-configurations)
8. [Gemini Enterprise Integration (Optional)](#gemini-enterprise-integration-optional)

---

## Core Features

This MCP server exposes high-performance threat intelligence endpoints to any compatible LLM agent.

### 🔍 Intelligence & Hunting
- **`search_iocs(query, limit)`**: Queries Indicators of Compromise (IOCs) using advanced search filters.
- **`get_hunting_ruleset`** & **`get_entities_related_to_a_hunting_ruleset`**: Accesses and maps structured threat detection signatures.

### 📁 Files & Artifacts
- **`get_file_report(hash)`**: Inspects MD5, SHA1, or SHA256 hashes to check multi-engine detections and threat actor classifications.
- **`get_file_behavior_report(id)`** & **`get_file_behavior_summary(hash)`**: Retreives deep sandbox execution data.

### 🌐 Domains, IPs, and URLs
- **`get_domain_report(domain)`** & **`get_entities_related_to_a_domain`**: Resolves passive DNS mappings, registrar details, and reputational classifications.
- **`get_ip_address_report(ip_address)`**: Retrieves geolocations, Autonomous System Numbers (ASN), and detections.
- **`get_url_report(url)`** & **`get_entities_related_to_an_url`**: Inspects specific URLs.

---

## Configuration & Customization (Optional)

This project is pre-configured and completely ready to run out-of-the-box. **You do not need to modify any of these files to deploy.** However, if you have specific network or architectural requirements, you can customize these configuration files:

| File Path | Purpose | Modification Details |
| :--- | :--- | :--- |
| **`docker-compose.yml`** | Local Container Config | Change the container port mappings or local environment references if needed. |
| **`Dockerfile`** | Image Build Spec | Customize the base Python version or update build-stage packages. |

> [!IMPORTANT]
> **Zero-Credential File Design**: No secrets or API keys are written to disk in this repository. Local development utilizes memory-only shell environment variables, and production environments strictly load keys from cloud-managed secret vaults.

---

## Local Development & Setup

### Prerequisites
- Python **3.11** or higher.
- A valid Google Threat Intelligence (VirusTotal) API key.

### Quick Start (Local Python)

1. **Clone the repository & enter the directory:**
   ```bash
   git clone <your-repository-url>
   cd gti-mcp-server
   ```

2. **Configure your API Key (In-Memory Only):**
   Export your Google Threat Intelligence API key directly in your terminal session. This key resides only in your shell's temporary RAM and is never written to disk:
   ```bash
   export VT_APIKEY="your_actual_gti_api_key_here"
   ```

3. **Install the package and dependencies:**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install --upgrade pip
   pip install -e .
   ```

4. **Run the server locally:**
   ```bash
   # Run in stdio mode (default, for local Desktop agents):
   gti-mcp-server

   # Run in SSE/HTTP network mode (for cloud simulation or container testing):
   TRANSPORT=sse PORT=8000 gti-mcp-server
   ```

---

## Containerization & Docker

This server is packaged with a high-performance, secure **multi-stage Docker build**. The builder stage packages the application into a Python wheel, and the runner stage installs it into a slim environment running as a restricted, non-root system user (`mcpuser` with UID 10001).

### 1. Build the Docker Image
```bash
docker build -t gti-mcp-server:latest .
```

### 2. Run with Docker Compose
Using Docker Compose binds the container to port `8000` and loads configuration from your `.env` file:
```bash
docker compose up -d
```

---

## Production Google Cloud Run Deployment (Strict Secret Manager)

This section provides a secure-by-default, step-by-step walkthrough for deploying to Google Cloud Run. It uses **Google Secret Manager** for credential storage and restricts invocations using **GCP IAM OIDC Authentication** (disallowing unauthenticated access).

### Step 1: Set Your Deployment Variables
Replace the placeholder values below with your GCP details:
```bash
PROJECT_ID="your-gcp-project-id"   # Your GCP Project ID
REGION="us-central1"               # GCP Region to deploy to
REPO="mcp-servers"                 # Artifact Registry Repository name
IMAGE="gti-mcp-server"             # Container Image name
```

### Step 2: Authenticate and Enable Required GCP Services
Authenticate your local shell session with Google Cloud and enable the APIs required for container hosting and secure secret storage:

```bash
# Authenticate your local shell session with Google Cloud
gcloud auth login

# Set your active gcloud project context
gcloud config set project ${PROJECT_ID}

# Enable Secret Manager, Artifact Registry, and Cloud Run APIs
gcloud services enable \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  run.googleapis.com
```

### Step 3: Secure your API Key in Google Secret Manager
Create a managed secret to host your Google Threat Intelligence (VirusTotal) API key securely:

1. **Create the Secret container:**
   ```bash
   gcloud secrets create VT_APIKEY --replication-policy="automatic"
   ```

2. **Add your API key value as version 1 of the secret:**
   *Replace `YOUR_ACTUAL_GTI_API_KEY` with your actual token:*
   ```bash
   echo -n "YOUR_ACTUAL_GTI_API_KEY" | gcloud secrets versions add VT_APIKEY --data-file=-
   ```

### Step 4: Grant Access to the Cloud Run Service Account
Cloud Run services run under a designated service account. By default, Cloud Run uses the **Compute Engine default service account** to call other GCP APIs.

1. **Get your Project Number:**
   ```bash
   PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
   echo "Your Project Number is: ${PROJECT_NUMBER}"
   ```

2. **Determine the Default Service Account Email:**
   The default service account email follows the pattern: `${PROJECT_NUMBER}-compute@developer.gserviceaccount.com`

3. **Grant Secret Accessor permission to this service account:**
   This authorizes the Cloud Run container to fetch and decrypt the secret at startup:
   ```bash
   gcloud secrets add-iam-policy-binding VT_APIKEY \
     --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```

### Step 5: Deploy to Cloud Run (Choose Your Path)

You can choose either of these two paths to compile and deploy your server. **Option A is highly recommended for non-technical users as it does not require Docker or manual registry configurations!**

#### 🚀 Option A: Direct Source-to-Cloud Deployment (No Local Docker Required)
This is the fastest, simplest method. Google Cloud will securely package your source directory, upload it, run **Google Cloud Build** in the background using your `Dockerfile`, automatically provision a private Artifact Registry under the hood, and deploy the service. 

Simply run this single command from your repository root:
```bash
gcloud run deploy gti-mcp-server \
  --source . \
  --region=${REGION} \
  --platform=managed \
  --no-allow-unauthenticated \
  --set-secrets="VT_APIKEY=VT_APIKEY:latest" \
  --set-env-vars="TRANSPORT=sse" \
  --port=8000 \
  --max-instances=5 \
  --cpu=1 \
  --memory=512Mi \
  --no-cpu-throttling
```

---

#### 🐳 Option B: Traditional Docker Build, Push, & Deploy
Choose this path if you prefer to compile, tag, and push your container image using Docker running locally on your laptop:

1. **Create the Docker repository in Artifact Registry:**
   ```bash
   gcloud artifacts repositories create ${REPO} \
     --repository-format=docker \
     --location=${REGION} \
     --description="MCP Servers Repository"
   ```

2. **Authenticate Docker to push to your GCP registry:**
   ```bash
   gcloud auth configure-docker ${REGION}-docker.pkg.dev
   ```

3. **Build and Tag the image (Intel/AMD64 target format):**
   ```bash
   docker build --platform linux/amd64 -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}:latest .
   ```

4. **Push the image to GCP:**
   ```bash
   docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}:latest
   ```

5. **Deploy the pushed image to Cloud Run:**
   ```bash
    gcloud run deploy gti-mcp-server \
      --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}:latest \
      --region=${REGION} \
      --platform=managed \
      --no-allow-unauthenticated \
      --set-secrets="VT_APIKEY=VT_APIKEY:latest" \
      --set-env-vars="TRANSPORT=sse" \
      --port=8000 \
      --max-instances=5 \
      --cpu=1 \
      --memory=512Mi \
      --no-cpu-throttling
   ```

> [!SUCCESS]
> Your secure GTI MCP server is now running! It will print a **Service URL** (e.g., `https://gti-mcp-server-xxxxxx-uc.a.run.app`). To automate subsequent registration and integration steps, **programmatically extract and store your newly deployed Service URL** directly in your shell environment:
> 
> ```bash
> # Dynamically retrieve and store your Cloud Run service URL
> export SERVICE_URL=$(gcloud run services describe gti-mcp-server --region=${REGION} --format="value(status.url)")
> ```

---

## Gemini Enterprise Integration

You can easily register this secure Cloud Run MCP server with **Gemini Enterprise** using Google Cloud's centralized **Agent Registry (Preview)**. This allows your enterprise AI agents, chat assistants, and Workspace environments to discover and securely invoke your Google Threat Intelligence tools.

Follow these command-driven steps to register your server:

### Step 1: Enable the Agent Registry API
Enable the required central services in your active Google Cloud project:
```bash
gcloud services enable agentregistry.googleapis.com
```

### Step 2: Register the Service in the Agent Registry
Register your Cloud Run MCP service. This leverages your dynamically captured `${SERVICE_URL}` variable with zero copy-pasting needed:
```bash
gcloud alpha agent-registry services create gti-mcp-service \
    --project=${PROJECT_ID} \
    --location=${REGION} \
    --display-name="Google Threat Intelligence" \
    --description="Exposes Google Threat Intelligence (VirusTotal) capabilities for analyzing files, URLs, netlocs, and threat profiles." \
    --interfaces="url=${SERVICE_URL}/sse,protocolBinding=JSONRPC" \
    --endpoint-spec-type=no-spec
```

### Step 3: Verify Your Registered Server
List and describe your registered server from the CLI to verify it was created successfully:
```bash
# List all registered services
gcloud alpha agent-registry services list \
    --project=${PROJECT_ID} \
    --location=${REGION}

# Describe your new GTI service
gcloud alpha agent-registry services describe gti-mcp-service \
    --project=${PROJECT_ID} \
    --location=${REGION}
```

Once registered, your Google Threat Intelligence tools are securely logged in Google's enterprise registry plane and ready for integration with your Workspace and generative AI apps!
