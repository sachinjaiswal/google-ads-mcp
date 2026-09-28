# Use a slim Python image
FROM python:3.11-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory in the container
WORKDIR /app

# Copy the project files into the container
COPY . .

# Install the project and its dependencies
# Pin FastMCP to the version required by the compatibility guard below.
RUN uv pip install --system ".[firestore]" "fastmcp==4.0.3"

# Codex CLI 0.146 reports the RFC 9207 iss value as missing from the local
# OAuth callback. Preserve the upstream version-guarded compatibility patch.
RUN python -c "from importlib.metadata import version; from pathlib import Path; assert version('fastmcp') == '4.0.3'; p = Path('/usr/local/lib/python3.11/site-packages/fastmcp/server/auth/oauth_proxy/proxy.py'); s = p.read_text(); old = 'metadata.authorization_response_iss_parameter_supported = True'; new = 'metadata.authorization_response_iss_parameter_supported = False'; assert s.count(old) == 1; p.write_text(s.replace(old, new))"

LABEL io.google-mcp.workaround="openai-codex-0146-rfc9207-iss"

EXPOSE 8080
CMD ["google-ads-mcp"]
