# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Add lifespan support for startup/shutdown with strong typing
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator
from dataclasses import dataclass

import logging
import os
import vt

from mcp.server.fastmcp import FastMCP, Context

logging.basicConfig(level=logging.ERROR)

# If True, creates a completely fresh transport for each request
# with no session tracking or state persistence between requests.
stateless = False
if os.getenv("STATELESS") == "1":
  stateless = True


def _vt_client_factory(unused_ctx) -> vt.Client:
  api_key = os.getenv("VT_APIKEY")
  if not api_key:
    raise ValueError("VT_APIKEY environment variable is required")
  return vt.Client(api_key)

vt_client_factory = _vt_client_factory


@asynccontextmanager
async def vt_client(ctx: Context) -> AsyncIterator[vt.Client]:
  """Provides a vt.Client instance for the current request."""
  client = vt_client_factory(ctx)

  try:
    yield client
  finally:
    await client.close_async()

# Create a named server and specify dependencies for deployment and development
server = FastMCP(
    "Google Threat Intelligence MCP server",
    dependencies=["vt-py"],
    stateless_http=stateless)

# Load tools.
from gti_mcp_server.tools import *

# Run the server
def main():
  # Detect transport from environment, default to stdio
  transport_env = os.getenv("TRANSPORT", "").strip().lower()
  port_env = os.getenv("PORT")

  if transport_env:
    transport = transport_env
  elif port_env:
    # If PORT is specified but TRANSPORT is not, default to sse
    transport = "sse"
  else:
    transport = "stdio"

  if transport in ("sse", "http"):
    # Set logging level to INFO so we see server start logs
    logging.getLogger().setLevel(logging.INFO)
    logging.info("Starting FastMCP server with SSE transport")
    
    # Map standard PORT and HOST variables to FastMCP's expected config vars
    if port_env:
      os.environ["FASTMCP_PORT"] = port_env
    elif "PORT" in os.environ:
      os.environ["FASTMCP_PORT"] = os.environ["PORT"]
    else:
      os.environ["FASTMCP_PORT"] = "8000"
      
    os.environ["FASTMCP_HOST"] = os.environ.get("HOST", "0.0.0.0")
    
    # Overwrite FastMCP's cached settings to bypass the import-time timing quirk
    server.settings.host = os.environ["FASTMCP_HOST"]
    server.settings.port = int(os.environ["FASTMCP_PORT"])
    
    server.run(transport="sse")
  else:
    logging.info("Starting FastMCP server with stdio transport")
    server.run(transport="stdio")


if __name__ == '__main__':
  main()
