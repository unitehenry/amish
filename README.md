## Setup Guide

<a href="https://cloud.digitalocean.com/apps/new?repo=https://github.com/unitehenry/amish/tree/main">
 <img src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to DO">
</a>

The one-click deploy will work out of the box, but here are some recommended ways to secure your deployment:

- [Guacamole Credentials](#guacamole-credentials)
- [Configure GitHub OAuth App](#configure-github-oauth-app)

### Guacamole Credentials

Update the following `guacamole` environment variables:

- `USERNAME`
- `PASSWORD`

These will be used to remotely control your browser.

### Configure GitHub OAuth App

Use GitHub OAuth to protect your MCP server. Navigate to your [developer settings](https://github.com/settings/developers) to create a GitHub OAuth App with the following settings:

- Homepage URL: `https://amish.you-app.com` (replace host with your deployment live URL)
- Callback URL: `https://amish.you-app.com/auth/callback` (replace host with your deployment URL)

Update the following `agent-browser-mcp` environment variables:

- `GITHUB_CLIENT_ID` - The client ID of your GitHub OAuth App.
- `GITHUB_CLIENT_SECRET` - The client secret of your GitHub OAuth App.
- `GITHUB_USERNAME` - This is the GitHub username to allow authentication to your MCP server.
- `BASE_URL` - `https://amish.you-app.com` (replace host with your deployment live URL)

## Usage

### Access your browser via browser

```
https://amish.your-app.com/guacamole

Default Credentials
    Username: admin
    Password: password
```

### Use your browser via MCP

> [!NOTE]
> Update the `MCP_TRANSPORT` environment variable under `agent-browser-mcp` settings if you wish to use another [transport method](https://gofastmcp.com/servers/context#transport).

```
https://amish.your-app.com/sse
```

## Architecture

```
todo: mermaid diagram
```
