# Google Threat Intelligence MCP Server

A production-ready, highly optimized Model Context Protocol (MCP) server for Google Threat Intelligence (GTI) (incorporating VirusTotal and Mandiant threat analytics). This server supports cloud-native network deployments via Stateless HTTP (streamable-http) or Server-Sent Events (SSE), making it fully compatible with Google Cloud Run or any other container-native environment.

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
4. [Getting Started](#getting-started)
5. [Local Development & Setup](#local-development--setup)
   - [Verifying Your Local SSE Server (No Agent Required)](#-verifying-your-local-sse-server-no-agent-required)
6. [Containerization & Docker](#containerization--docker)
7. [Production Google Cloud Run Deployment (Strict Secret Manager)](#production-google-cloud-run-deployment-strict-secret-manager)
   - [Verifying Your Cloud Run Stateless HTTP Server (No Agent Required)](#-verifying-your-cloud-run-stateless-http-server-no-agent-required)
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

## Getting Started

Regardless of whether you plan to run the server locally, package it in a container, or deploy it directly to Google Cloud Run, you must first clone the repository and navigate into the project directory:

```bash
# Clone this repository
git clone <your-repository-url>

# Enter the project directory
cd gti-mcp-server
```

### 🚀 Choose Your Path
Once inside the directory, choose the section that matches your goal:
- 💻 **Laptop (Python)**: Proceed to [Local Development & Setup](#local-development--setup).
- 🐳 **Local Docker Container**: Skip to [Containerization & Docker](#containerization--docker).
- ☁️ **Google Cloud Run (Production)**: Skip to [Production Google Cloud Run Deployment](#production-google-cloud-run-deployment-strict-secret-manager).

---

## Local Development & Setup

### Prerequisites
- Python **3.11** or higher.
- A valid Google Threat Intelligence (VirusTotal) API key.

### Quick Start (Local Python)

1. **Configure your API Key (In-Memory Only):**
   Export your Google Threat Intelligence API key directly in your terminal session. This key resides only in your shell's temporary RAM and is never written to disk:
   ```bash
   export VT_APIKEY="your_actual_gti_api_key_here"
   ```

2. **Install the package and dependencies:**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install --upgrade pip
   pip install -e .
   ```

3. **Run the server locally:**

   Start the server in SSE/HTTP network mode. This boots the server as an HTTP service listening on port 8000 by default and outputs active startup logs once initialized:
   ```bash
   gti-mcp-server
   ```


### 🧪 Verifying Your Local SSE Server (No Agent Required)

Because Model Context Protocol (MCP) uses **Server-Sent Events (SSE)** under the hood, you can verify your local server using standard command-line tools without needing a desktop AI client or agent installed. 

This test requires **two additional terminal windows (or tabs)**, leaving your local server running in your current window from the previous step:

#### Step 1: Run the Server (Terminal Window 1)
This is the server you already started in the previous **Quick Start** step! 
*(If you stopped it, simply open Terminal Window 1, activate your virtual environment, and run `gti-mcp-server` again).*
*Leave this server running.*

#### Step 2: Open the Event Stream (Terminal Window 2)
Establish a streaming SSE connection. Because SSE is a streaming protocol, this connection will stay open ("hanging") to capture real-time responses:
```bash
curl -i -N http://localhost:8000/sse
```

**What you will see:**
It will connect instantly and output the initial dynamic connection endpoint along with a unique session ID:
```http
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

event: endpoint
data: /messages/?session_id=a1b2c3d4e5f6...
```
*Leave this window running and copy your generated `session_id`.*

#### Step 3: Perform the Handshake and Run Queries (Terminal Window 3)
In your third terminal window, run the following three requests sequentially (substituting your copied `session_id`) to complete the protocol handshake and list your tools:

1. **Initialize the MCP Session:**
   ```bash
   curl -X POST \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "id": 1,
       "method": "initialize",
       "params": {
         "protocolVersion": "2024-11-05",
         "capabilities": {},
         "clientInfo": {
           "name": "curl-test-client",
           "version": "1.0"
         }
       }
     }' \
     "http://localhost:8000/messages/?session_id=YOUR_ACTIVE_SESSION_ID"
   ```
   *(Check Terminal Window 1: you will see a streamed `message` event containing the server's protocol capabilities).*

2. **Confirm Handshake Completion:**
   ```bash
   curl -X POST \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "method": "notifications/initialized"
     }' \
     "http://localhost:8000/messages/?session_id=YOUR_ACTIVE_SESSION_ID"
   ```

3. **List Available Threat Intelligence Tools:**
   ```bash
   curl -X POST \
     -H "Content-Type: application/json" \
     -d '{
       "jsonrpc": "2.0",
       "id": 2,
       "method": "tools/list",
       "params": {}
     }' \
     "http://localhost:8000/messages/?session_id=YOUR_ACTIVE_SESSION_ID"
   ```

**Look back at Terminal Window 1:** You will see a complete, beautiful JSON-RPC stream containing all your Google Threat Intelligence capabilities (`get_file_report`, `search_iocs`, etc.)!

---

## Containerization & Docker (Alternative)

This server is pre-configured with a secure, multi-stage **Docker build spec** and a companion **Docker Compose** layout. 

Since `docker-compose.yml` is configured to build your container automatically, **you do not need to run a separate build command!** You can compile the image and launch the container on-the-fly with a single command:

```bash
# Make sure your API key is in your active terminal environment
export VT_APIKEY="your_actual_gti_api_key_here"

# Compile and start the server in the background
docker compose up -d
```

This starts the containerized server in the background, maps port `8000` to port `8000` on your host computer, and passes your terminal's `${VT_APIKEY}` directly into the secure container memory.

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
  --set-env-vars="TRANSPORT=http,STATELESS=1" \
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
      --set-env-vars="TRANSPORT=http,STATELESS=1" \
      --port=8000 \
      --max-instances=5 \
      --cpu=1 \
      --memory=512Mi \
      --no-cpu-throttling
   ```

### Step 6: Retrieve and Save Your Cloud Run Service URL
Once successfully deployed, retrieve your Cloud Run live service URL and export it as an environment variable in your terminal session. This variable is required to register your server with Gemini Enterprise later:

```bash
SERVICE_URL=$(gcloud run services describe gti-mcp-server --region=${REGION} --format="value(status.url)")
echo "Your live Service URL is: ${SERVICE_URL}"
```

> [NOTE]
> Setting `host="0.0.0.0"` in our server configuration ensures that the container is fully compatible with Cloud Run and can accept incoming production connections smoothly.

### 🧪 Verifying Your Cloud Run Stateless HTTP Server (No Agent Required)

Once your service is deployed, you can verify that the live production server is functioning, authenticated, and communicating properly over the network without needing to set up an AI agent first.

Using the official Google Cloud secure proxy is the **simplest, safest, and most recommended method** because it handles OAuth authentication and Host headers automatically.

This test requires **two separate terminal windows (or tabs)**:

#### Step 1: Start the Cloud Run Proxy (Terminal Window 1)
Run this command to boot up a secure local authentication tunnel mapped to port `8000`:
```bash
gcloud run services proxy gti-mcp-server --region=${REGION} --port 8000
```
*Leave this terminal running. It will output a confirmation log indicating that port 8000 is proxying to your secure Cloud Run service.*

#### Step 2: Query the Tools List (Terminal Window 2)
In your second terminal window, send a single JSON-RPC POST request to the proxied server at `/mcp` to list all available tools:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
  }' \
  "http://localhost:8000/mcp"
```

**What you will see:**
It will connect instantly and output a beautiful JSON-RPC response containing your entire suite of Google Threat Intelligence tools (`get_file_report`, `search_iocs`, etc.) served directly from your secure Cloud Run deployment!

---

## Gemini Enterprise Integration (Optional)

You can easily connect and register this secure Cloud Run MCP server directly with your **Gemini Enterprise App** (such as `default-chat` within Vertex AI Agent Builder) using a 100% command-line driven **Discovery Engine custom MCP data store** workflow.

Follow these command-driven steps to enable the required APIs, configure your OAuth identity provider, create your data store, authorize security, enable threat intelligence actions, and link them to Gemini:

### Step 1: Enable Required APIs
Enable the advanced core APIs required for Discovery Engine custom datastores first, as initialization may take a minute:
```bash
gcloud services enable discoveryengine.googleapis.com \
  --project=${PROJECT_ID}
```

### Step 2: Define Your OAuth Endpoints
Configure your session variables for your OAuth identity provider (required by Discovery Engine to federate and authenticate custom MCP servers):
```bash
# Default Google Cloud Identity OAuth 2.0 endpoints (change these if you are using a custom/external Identity Provider)
AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL="https://oauth2.googleapis.com/token"
```

### Step 3: Create an OAuth Client ID
Because OAuth Clients cannot be created programmatically via `gcloud` APIs, you must create one manually in the Google Cloud Console:
1. Navigate to the [Google Cloud Console API Credentials page](https://console.cloud.google.com/apis/credentials).
2. Click **Create Credentials** > **OAuth client ID**.
3. Select **Web application** as the application type.
4. Name your client (e.g., `GTI MCP Server Client`).
5. Under **Authorized redirect URIs**, add any redirect URIs if required by your identity environment.
6. Click **Create** and copy your **Client ID** and **Client Secret**.

Once you have your credentials, define them in your active terminal session:
```bash
CLIENT_ID="your-client-id"                      # Replace with your copied OAuth Client ID
CLIENT_SECRET="your-client-secret"              # Replace with your copied OAuth Client Secret
```

> [!TIP]
> For more details on Google's OAuth 2.0 implementation and general concepts, refer to the [Official Google Identity OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2).

### Step 4: Create the Custom MCP Data Store (via setUpDataConnector REST API)
Because the `discoveryengine` command group is not standard in the public `gcloud` SDK, use **`curl`** to invoke the Discovery Engine custom MCP setup API directly.

First, define your Discovery Engine settings:
```bash
LOCATION="us"                           # Discovery Engine location (e.g., us, global)
COLLECTION_ID="gti-mcp-server-collection"  # Your unique collection identifier
DISPLAY_NAME="Google Threat Intelligence Tools"
```

Now, execute the API call to establish a federated custom MCP connector:
```bash
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  -H "Content-Type: application/json" \
  -d '{
    "collectionDisplayName": "'"${DISPLAY_NAME}"'",
    "dataConnector": {
      "dataSource": "custom_mcp",
      "connectorSourceId": "custom_mcp",
      "params": {
        "oauth_access_token": "unused",
        "auth_type": "AUTHORIZATION_TYPE_UNDEFINED"
      },
      "refreshInterval": "86400s",
      "entities": [
        {
          "entityName": "mcp_data"
        }
      ],
      "dataSourceVersion": 1,
      "staticIpEnabled": false,
      "actionConfig": {
        "actionParams": {
          "instance_uri": "'"${SERVICE_URL}"'/mcp",
          "auth_uri": "'"${AUTH_URL}"'",
          "token_uri": "'"${TOKEN_URL}"'",
          "client_id": "'"${CLIENT_ID}"'",
          "client_secret": "'"${CLIENT_SECRET}"'",
          "scopes": "openid",
          "auth_type": "OAUTH",
          "mcp_server_description": "Google Threat Intelligence (GTI) MCP server. Exposes tools to query Indicators of Compromise (IOCs), threat analytics, domain and IP address intelligence, and file/artifact reputation or sandbox analysis.",
          "mcp_agent_instructions": "You are a security analyst assistant. Use this Google Threat Intelligence (GTI) MCP server to analyze security threats, investigate network artifacts (domains, IPs, URLs), and query file reports or execution behaviors. Always validate hash formats (MD5, SHA1, SHA256) and ensure domain inputs are stripped of protocol schemas before querying.",
          "mcp_server_source": "BYO_MCP"
        },
        "createBapConnection": true,
        "isActionConfigured": false
      },
      "connectorModes": [
        "FEDERATED"
      ]
    }
  }' \
  "https://${LOCATION}-discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/${LOCATION}:setUpDataConnector?collectionId=${COLLECTION_ID}"
```

### Step 5: Authorize the Gemini Enterprise Service Account (IAM)
Because your Cloud Run service is locked down securely (`--no-allow-unauthenticated`), you must explicitly authorize the Gemini Enterprise Discovery Engine system service account to call and invoke your Cloud Run endpoint.

Run these commands to bind the **Cloud Run Invoker** role:
```bash
# Retrieve your active Discovery Engine system service account email
DISCOVERY_ENGINE_SA="service-${PROJECT_NUMBER}@gcp-sa-discoveryengine.iam.gserviceaccount.com"

# Grant it invoker rights to your Cloud Run service
gcloud run services add-iam-policy-binding gti-mcp-server \
    --member="serviceAccount:${DISCOVERY_ENGINE_SA}" \
    --role="roles/run.invoker" \
    --region=${REGION} \
    --project=${PROJECT_ID}
```

### Step 6: Reload and Enable Your Actions (GCP Console UI)
Because the custom actions discovery and OAuth consent handshake are handled securely by Google Cloud Console's frontend, you must perform a one-time manual reload to authorize and activate your threat intelligence tools:

1. Open the [Google Cloud Agent Builder Data Stores Console](https://console.cloud.google.com/ai/search/datastores).
2. Select your newly created **Google Threat Intelligence Tools** data store.
3. Click on the **Actions** tab on the left-hand navigation pane.
4. If prompted, click **Re-authenticate** to sign in and complete the OAuth connection.
5. Click the **Reload custom actions** button. This will connect to your Cloud Run service's `/mcp` endpoint and dynamically populate all 45+ GTI tools.
6. Select the tools you want to enable, and click **Enable actions**.

---

### Step 7: Link the Custom MCP Data Store to your Gemini App (GCP Console UI)
Finally, link your newly configured threat intelligence data store to your active Gemini App configuration (e.g., your chat or search application):

1. Open the [Gemini Enterprise Console](https://console.cloud.google.com/gemini-enterprise/apps).
2. In the left-hand navigation pane, click on **Apps** 
3. Click on your Gemini Enterprise application
4. In the left-hand navigation pane, click on **Connected data stores**.
5. Click **Add existing data store**
6. Select your newly created **Google Threat Intelligence Tools** data store from the list.
7. Click **Connect** (or **Save**) to confirm.

Your Gemini Enterprise conversational app is now fully integrated with real-time Google Threat Intelligence capabilities, securely authorized, and ready to assist your security operations team! 🚀

