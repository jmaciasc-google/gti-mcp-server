#!/usr/bin/env bash

# ==============================================================================
# Google Threat Intelligence MCP Server - Verification Script
# ==============================================================================
# This script verifies the MCP server is working over the SSE transport layer
# without requiring an agent or external client.
# It automatically detects if the target is a remote deployment and fetches
# a Google OIDC token using 'gcloud' to authorize requests if needed.
# ==============================================================================

set -eo pipefail

# ANSI color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOST=${HOST:-"localhost"}
PORT=${PORT:-"8080"}

# Format the base URL correctly (use https for secure remotes, http for localhost)
if [[ "$HOST" == "localhost" || "$HOST" == "127.0.0.1" ]]; then
    BASE_URL="http://${HOST}:${PORT}"
else
    # Remote deployments are typically served over HTTPS on standard port 443
    if [ "$PORT" = "8080" ]; then
        BASE_URL="https://${HOST}"
    else
        BASE_URL="https://${HOST}:${PORT}"
    fi
fi

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Google Threat Intelligence MCP Server Verification Script      ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed.${NC}" >&2
    exit 1
fi

# Detect and configure OIDC authentication for secure remote deployments
AUTH_HEADERS=()
if [[ "$HOST" != "localhost" && "$HOST" != "127.0.0.1" ]]; then
    echo -e "Target is remote. Attempting to generate Google OIDC token via local gcloud context..."
    if command -v gcloud &> /dev/null; then
        # Try generating the OIDC token with the service URL as audience
        AUDIENCE_URL="https://${HOST}"
        if ID_TOKEN=$(gcloud auth print-identity-token --audiences="${AUDIENCE_URL}" 2>/dev/null); then
            echo -e "${GREEN}✓ Successfully generated GCP OIDC ID token!${NC}"
            AUTH_HEADERS=(-H "Authorization: Bearer ${ID_TOKEN}")
        else
            echo -e "${YELLOW}Warning: Failed to generate OIDC token via gcloud. Check your 'gcloud auth login' status.${NC}"
            echo -e "Attempting unauthenticated connection..."
        fi
    else
        echo -e "${YELLOW}Warning: gcloud CLI not found. Unable to automatically generate OIDC token.${NC}"
        echo -e "Attempting unauthenticated connection..."
    fi
fi

# Check connectivity to MCP Server
echo -e "Checking connectivity to MCP Server at: ${YELLOW}${BASE_URL}${NC} ..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${AUTH_HEADERS[@]}" "${BASE_URL}/sse" || echo "000")

if [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "403" ]; then
    echo -e "${RED}Error: Received $HTTP_STATUS Forbidden/Unauthorized response.${NC}"
    echo -e "The server requires authentication. Ensure you are authorized and passing a valid OIDC token."
    exit 1
elif [ "$HTTP_STATUS" = "000" ] || [ "$HTTP_STATUS" -ge 400 ]; then
    echo -e "${RED}Error: Cannot connect to the server at ${BASE_URL} (Status Code: $HTTP_STATUS).${NC}"
    echo -e "${YELLOW}Please ensure your server is running. You can start it via:${NC}"
    echo -e "  - Docker Compose:  ${GREEN}docker compose up -d${NC} (from the repository root)"
    echo -e "  - Local Python:    ${GREEN}uv run gti-mcp-server --transport sse --port 8080${NC}"
    echo -e ""
    exit 1
fi

echo -e "${GREEN}✓ Successfully connected to the server!${NC}"
echo -e "Establishing Server-Sent Events (SSE) session to extract Session ID..."

# Fetch the SSE stream and capture the first "data:" line to extract the message path.
SSE_OUTPUT=$(curl -s -N --max-time 5 "${AUTH_HEADERS[@]}" "${BASE_URL}/sse")

# Find the message path
MSG_PATH=$(echo "$SSE_OUTPUT" | grep -m 1 "data:" | sed 's/data:[[:space:]]*//' | tr -d '\r\n')

if [ -z "$MSG_PATH" ]; then
    echo -e "${RED}Error: Failed to extract session endpoint from the SSE stream.${NC}"
    echo -e "Raw SSE output received:"
    echo -e "${YELLOW}${SSE_OUTPUT}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Session established successfully!${NC}"
echo -e "Session message endpoint: ${YELLOW}${MSG_PATH}${NC}"
echo -e "Sending JSON-RPC ${BLUE}\"tools/list\"${NC} request..."

# Send standard JSON-RPC tools/list request to the message endpoint
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  "${AUTH_HEADERS[@]}" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "params": {}, "id": 1}' \
  "${BASE_URL}${MSG_PATH}")

# Check if response is valid JSON and contains tools
if echo "$RESPONSE" | grep -q "result"; then
    echo -e "${GREEN}✓ Received valid JSON-RPC response from the server!${NC}"
    echo -e "\n${BLUE}Available Tools found in Google Threat Intelligence MCP Server:${NC}"
    
    # Try using python to pretty-print tool names, fallback to raw response if python is missing
    if command -v python3 &> /dev/null; then
        python3 -c "
import sys, json
try:
    data = json.loads(sys.argv[1])
    tools = data.get('result', {}).get('tools', [])
    print(f'Total Tools: {len(tools)}')
    print('-' * 60)
    for tool in tools:
        print(f' - \033[1;32m{tool.get(\"name\")}\033[0m: {tool.get(\"description\", \"\")[:80]}...')
except Exception as e:
    print('Raw response:', sys.argv[1])
" "$RESPONSE"
    else:
        echo -e "${YELLOW}Raw Response:${NC}"
        echo "$RESPONSE"
    fi
    echo -e "\n${GREEN}Verification complete! The Google Threat Intelligence MCP Server is fully operational.${NC}"
else
    echo -e "${RED}Error: Did not receive a valid JSON-RPC response.${NC}"
    echo -e "Response received:"
    echo -e "${YELLOW}${RESPONSE}${NC}"
    exit 1
fi
