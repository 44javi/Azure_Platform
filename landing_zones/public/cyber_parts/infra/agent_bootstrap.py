#!/usr/bin/env python3
"""
Bootstrap (version) the Cybernetic Nimbus Foundry agent after Terraform.

Targets the NEW Foundry (prompt agents on the Responses protocol), NOT the
classic hub-based Agent Service. Creating a version is an upsert: each run
adds a new version under the stable agent_name (live agent is already
at version 3).

Requirements:
    pip install "azure-ai-projects>=2.0.0b4" azure-identity

Network constraint:
    Foundry + Search are private-endpoint only. Run from inside the spoke
    VNet (snet-buildagents, jump box, or a private-linked pipeline runner).

Identities (two different ones — don't conflate):
    * Caller (DefaultAzureCredential running this script): needs project
      data-plane rights to create agent versions and read connections,
      e.g. "Azure AI Project Manager" / "Azure AI User" on the project.
    * Project runtime managed identity (used at query time): needs
      "Search Index Data Reader" on the search service AND
      "Storage Blob Data Reader" on the blob account backing the index.
      New Foundry agents do NOT inherit permissions from the caller.

Usage:
    python agent_bootstrap.py
    ENVIRONMENT=dev SEARCH_CONNECTION_NAME=conn-search SEARCH_INDEX_NAME=idx-main python agent_bootstrap.py
"""

import logging
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AzureAISearchTool,          # some package versions / docs name this AzureAISearchAgentTool
    AzureAISearchToolResource,
    AISearchIndexResource,
    AzureAISearchQueryType,
    PromptAgentDefinition,
)
from azure.core.exceptions import HttpResponseError
from azure.identity import DefaultAzureCredential

# ---------------------------------------------------------------------------
# Config — edit here or override via env vars
# ---------------------------------------------------------------------------

PROJECT      = os.getenv("TF_VAR_project",     "")
ENVIRONMENT  = os.getenv("TF_VAR_environment", "")
ACCOUNT      = os.getenv("FOUNDRY_ACCOUNT",    f"cdn-foundry-{PROJECT}-{ENVIRONMENT}")
PROJECT_NAME = os.getenv("PROJECT_NAME",       f"proj-{PROJECT}-{ENVIRONMENT}")

# New Foundry wants the PROJECT ENDPOINT URL, not a connection string.
# Format: https://<account>.services.ai.azure.com/api/projects/<project>
# Verify against Portal > your project > Overview/Endpoints > "Foundry project endpoint".
PROJECT_ENDPOINT = os.getenv(
    "FOUNDRY_PROJECT_ENDPOINT",
    f"https://{ACCOUNT}.services.ai.azure.com/api/projects/{PROJECT_NAME}",
)

AGENT_NAME   = os.getenv("AGENT_NAME", "cybernetic-nimbus-assistant")
MODEL        = os.getenv("MODEL",      "chat")   # MUST match a real model *deployment* name (Models tab)
INSTRUCTIONS = os.getenv("INSTRUCTIONS", (
    "You are a helpful assistant for Cybernetic Nimbus. "
    "Use the Azure AI Search tool to look up relevant documents before "
    "answering questions about the company, services, or client onboarding "
    "and offboarding. Always cite the source document, rendering citations "
    "as \u3010message_idx:search_idx\u2020source\u3011."
))

# Set BOTH to enable AI Search grounding; leave blank to skip the tool.
SEARCH_CONNECTION_NAME = os.getenv("SEARCH_CONNECTION_NAME", "")  # connection name in the Foundry project
SEARCH_INDEX_NAME      = os.getenv("SEARCH_INDEX_NAME",      "")  # AI Search index name
# simple | semantic | vector | vector_simple_hybrid | vector_semantic_hybrid
SEARCH_QUERY_TYPE      = os.getenv("SEARCH_QUERY_TYPE", "simple")

# create_version is an upsert. Default behavior: if the agent already has at
# least one version, skip (avoid version churn on every pipeline run). Set
# FORCE_NEW_VERSION=true to always publish a new version.
FORCE_NEW_VERSION = os.getenv("FORCE_NEW_VERSION", "false").lower() == "true"

log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Client
# ---------------------------------------------------------------------------

def make_client() -> AIProjectClient:
    return AIProjectClient(endpoint=PROJECT_ENDPOINT, credential=DefaultAzureCredential())


# ---------------------------------------------------------------------------
# Tool + agent helpers
# ---------------------------------------------------------------------------

def build_search_tool(client: AIProjectClient) -> AzureAISearchTool:
    """Resolve the project connection and wrap the index as an AI Search tool.

    The connection must already exist (Project > Connected resources), point
    at https://srch-{project}-{env}.search.windows.net with Microsoft Entra
    (managed identity) auth — key auth can't reach a search service that has
    public access disabled.
    """
    conn = client.connections.get(SEARCH_CONNECTION_NAME)
    log.info("Resolved AI Search connection '%s' -> %s", SEARCH_CONNECTION_NAME, conn.id)
    return AzureAISearchTool(
        azure_ai_search=AzureAISearchToolResource(
            indexes=[
                AISearchIndexResource(
                    project_connection_id=conn.id,
                    index_name=SEARCH_INDEX_NAME,
                    query_type=AzureAISearchQueryType(SEARCH_QUERY_TYPE),
                ),
            ]
        )
    )


def has_existing_version(client: AIProjectClient, name: str) -> bool:
    """Best-effort existence check. list_versions raises if the agent is new.

    The exact return shape can vary by azure-ai-projects beta; this only needs
    to know whether *any* version exists, so we just probe the iterator.
    """
    try:
        return any(True for _ in client.agents.list_versions(agent_name=name))
    except HttpResponseError:
        return False


def bootstrap_agent(client: AIProjectClient) -> str:
    if not FORCE_NEW_VERSION and has_existing_version(client, AGENT_NAME):
        log.info(
            "Agent '%s' already has at least one version and FORCE_NEW_VERSION "
            "is off — skipping. Set FORCE_NEW_VERSION=true to publish a new one.",
            AGENT_NAME,
        )
        latest = client.agents.get_version(agent_name=AGENT_NAME)  # latest version
        return latest.id

    tools: list = []
    if SEARCH_CONNECTION_NAME and SEARCH_INDEX_NAME:
        tools = [build_search_tool(client)]
    elif SEARCH_CONNECTION_NAME or SEARCH_INDEX_NAME:
        log.warning(
            "Set BOTH SEARCH_CONNECTION_NAME and SEARCH_INDEX_NAME to enable "
            "search grounding. Skipping the tool."
        )

    agent = client.agents.create_version(
        agent_name=AGENT_NAME,
        definition=PromptAgentDefinition(
            model=MODEL,
            instructions=INSTRUCTIONS,
            tools=tools,
        ),
        description="Cybernetic Nimbus assistant (bootstrapped post-Terraform).",
    )
    log.info("Created agent '%s' version %s (id=%s).", agent.name, agent.version, agent.id)
    return agent.id


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(message)s")

    log.info("Endpoint: %s", PROJECT_ENDPOINT)
    log.info("Agent:    %s", AGENT_NAME)
    log.info("Model:    %s", MODEL)

    client = make_client()
    try:
        with client:
            agent_id = bootstrap_agent(client)
    except HttpResponseError as exc:
        log.error("Azure API error (%s): %s", exc.status_code, exc.message)
        sys.exit(1)

    # Pipeline-parseable output
    print(f"agent_id={agent_id}")


if __name__ == "__main__":
    main()
