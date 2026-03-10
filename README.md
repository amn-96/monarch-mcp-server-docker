## 🚀 Quick Start (Docker)

### 1. Pull the Docker Image

You can pull the pre-built image from the GitHub Container Registry (GHCR):

```bash
docker compose pull
```

*(Alternatively, you can build it yourself locally by running `docker compose build`)*

### 2. One-Time Authentication Setup (MFA)

**Important**: For security and MFA support, authentication is done interactively via Docker.

Run the interactive setup via Docker to securely store the session token in a persistent volume:

```bash
docker compose run --rm -it --entrypoint "python login_setup.py" monarch-mcp
```

Follow the prompts:
- Answer `y` if you have MFA enabled
- Enter your Monarch Money email and password
- Provide 2FA code if you have MFA enabled
- Session will be saved automatically to the `monarch-data` volume

*(For fully detailed instructions on MFA with Docker, see the [Docker MFA Instructions](docs/DOCKER_MFA_INSTRUCTIONS.md))*

### 3. Configure Claude Desktop

Add this to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Choose the config that matches how you're running the server:

#### stdio (default — local only)

Claude Desktop spawns the container as a subprocess. No network port needed.

```json
{
  "mcpServers": {
    "Monarch Money": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--volume",
        "monarch-data:/app/data",
        "ghcr.io/amn-96/monarch-mcp-server-docker:latest"
      ]
    }
  }
}
```

*(If using a locally built image, replace the image name with `monarch-mcp-server-docker-monarch-mcp`.)*

#### SSE (network — legacy)

Run `docker compose up monarch-mcp-sse` first, then configure Claude Desktop to connect over HTTP:

```json
{
  "mcpServers": {
    "Monarch Money": {
      "url": "http://your-server-ip:8000/sse"
    }
  }
}
```

#### Streamable HTTP (network — recommended)

Same as SSE but use `MCP_TRANSPORT=streamable-http` and the `/mcp` endpoint:

```json
{
  "mcpServers": {
    "Monarch Money": {
      "url": "http://your-server-ip:8000/mcp"
    }
  }
}
```
   
4. **Restart Claude Desktop**

### 4. Start Using in Claude Desktop

Once authenticated, use these tools directly in Claude Desktop:
- `get_accounts` - View all your financial accounts
- `get_transactions` - Recent transactions with filtering
- `get_budgets` - Budget information and spending
- `get_cashflow` - Income/expense analysis

## ⚠️ SECURITY WARNING: Network Exposure

**DO NOT expose this server to the public internet unless you know exactly what you are doing.**

When running in SSE mode, the server:
- Has **no authentication** — anyone who can reach the port can query your financial data
- Serves your Monarch Money session token over the network
- The keyring backend uses a **plaintext file** (`keyrings.alt`) inside the container

Safe usage: bind to `127.0.0.1` (localhost only) or a private LAN interface, and use a firewall or VPN to restrict access. Never bind to `0.0.0.0` on a machine with a public IP without a reverse proxy that handles authentication (e.g., nginx + basic auth + TLS).

## Remote Access (Network Transports)

To run the server over a network, use the `monarch-mcp-sse` service (supports both `sse` and `streamable-http`):

```bash
docker compose up monarch-mcp-sse
```

The server will listen on port 8000. See step 3 of Quick Start above for the Claude Desktop config for each transport mode.

This server supports three transports:

| Transport | How to use | Use case |
|-----------|------------|----------|
| `stdio` | Claude Desktop spawns the container as a subprocess | Default; local use only |
| `sse` | HTTP + Server-Sent Events; Claude connects to `/sse` | Network access (legacy) |
| `streamable-http` | HTTP streaming; Claude connects to `/mcp` | Network access (recommended) |

You can customize the transport, host, and port via environment variables:
- `MCP_TRANSPORT` — `sse` or `streamable-http` (default: `stdio`)
- `MCP_HOST` — bind address (default: `0.0.0.0`)
- `MCP_PORT` — port number (default: `8000`)

## ✨ Features

### 📊 Account Management
- **Get Accounts**: View all linked financial accounts with balances and institution info
- **Get Account Holdings**: See securities and investments in investment accounts
- **Refresh Accounts**: Request real-time data updates from financial institutions

### 💰 Transaction Access
- **Get Transactions**: Fetch transaction data with filtering by date, account, and pagination
- **Create Transaction**: Add new transactions to accounts
- **Update Transaction**: Modify existing transactions (amount, description, category, date)

### 📈 Financial Analysis
- **Get Budgets**: Access budget information including spent amounts and remaining balances
- **Get Cashflow**: Analyze financial cashflow over specified date ranges with income/expense breakdowns

### 🔐 Secure Authentication
- **One-Time Setup**: Authenticate once, use for weeks/months
- **MFA Support**: Full support for two-factor authentication
- **Session Persistence**: No need to re-authenticate frequently
- **Secure**: Credentials never pass through Claude Desktop

## 🛠️ Available Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `setup_authentication` | Get setup instructions | None |
| `check_auth_status` | Check authentication status | None |
| `get_accounts` | Get all financial accounts | None |
| `get_transactions` | Get transactions with filtering | `limit`, `offset`, `start_date`, `end_date`, `account_id` |
| `get_budgets` | Get budget information | None |
| `get_cashflow` | Get cashflow analysis | `start_date`, `end_date` |
| `get_account_holdings` | Get investment holdings | `account_id` |
| `create_transaction` | Create new transaction | `account_id`, `amount`, `description`, `date`, `category_id`, `merchant_name` |
| `update_transaction` | Update existing transaction | `transaction_id`, `amount`, `description`, `category_id`, `date` |
| `refresh_accounts` | Request account data refresh | None |

## 📝 Usage Examples

### View Your Accounts
```
Use get_accounts to show me all my financial accounts
```

### Get Recent Transactions
```
Show me my last 50 transactions using get_transactions with limit 50
```

### Check Spending vs Budget
```
Use get_budgets to show my current budget status
```

### Analyze Cash Flow
```
Get my cashflow for the last 3 months using get_cashflow
```

## 📅 Date Formats

- All dates should be in `YYYY-MM-DD` format (e.g., "2024-01-15")
- Transaction amounts: **positive** for income, **negative** for expenses

## 🔧 Troubleshooting

### Authentication Issues
If you see "Authentication needed" errors:
1. Run the interactive setup command: `docker compose run --rm -it --entrypoint "python login_setup.py" monarch-mcp`
2. Restart Claude Desktop
3. Try using a tool like `get_accounts`

### Session Expired
Sessions last for weeks, but if expired:
1. Run the same setup command again
2. Enter your credentials and 2FA code
3. Session will be refreshed automatically

### Common Error Messages
- **"No valid session found"**: Run `login_setup.py` through Docker.
- **"Invalid account ID"**: Use `get_accounts` to see valid account IDs
- **"Date format error"**: Use YYYY-MM-DD format for dates

## 🏗️ Technical Details

### Session Management
- Sessions are stored securely in the Docker volume `monarch-data` (using `keyrings.alt`)
- Automatic session discovery and loading
- Sessions persist across Claude Desktop restarts
- No need for frequent re-authentication

### Security Features
- Credentials never transmitted through Claude Desktop
- MFA/2FA fully supported
- Authentication handled in secure terminal environment

## �️ Archives (Non-Docker)

For the original local Python instructions (non-docker), please consult the archived documentation:
- [Original README](docs/ORIGINAL_README.md)

## 🙏 Acknowledgments
This repo is simply a dockerized version of the [original Monarch Money MCP server](https://github.com/robcerda/monarch-mcp-server) created by [@robcerda](https://github.com/robcerda).

This MCP server is built on top of the excellent [MonarchMoney Python library](https://github.com/hammem/monarchmoney) created by [@hammem](https://github.com/hammem). Their library provides the robust foundation that makes this integration possible, including:

- Secure authentication with MFA support
- Comprehensive API coverage for Monarch Money
- Session management and persistence
- Well-documented and maintained codebase

Thank you to [@hammem](https://github.com/hammem) for creating and maintaining this essential library!

## 📄 License

MIT License

## 🆘 Support

For issues:
1. Check authentication with `check_auth_status`
2. Run the setup command again: `docker compose run --rm -it --entrypoint "python login_setup.py" monarch-mcp`
3. Check error logs for detailed messages
4. Ensure Monarch Money service is accessible

## 🔄 Updates

To update the server:
1. Pull latest changes from repository (or latest docker image)
2. Restart Claude Desktop
3. Re-run authentication if needed.