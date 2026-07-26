## Setup Guide

<a href="https://cloud.digitalocean.com/apps/new?repo=https://github.com/unitehenry/amish/tree/main>
 <img src="https://www.deploytodo.com/do-btn-blue.svg" alt="Deploy to DO">
</a>

```sh
doctl apps create --spec deploy.template.yaml
```

The one-click deploy will work out of the box, but here are some recommended ways to secure your deploy:

- [Guacamole Credentials](#guacamole-credentials)
- [Configure GitHub OAuth App](#configure-github-oauth-app)

### Configure GitHub OAuth App

- https://github.com/settings/developers
- Callback URL: https://amish.you-app.com/auth/callback

## Usage

**Access your browser via browser**

```
https://amish.your-app.com/guacamole

Default Credentials
    Username: admin
    Password: password
```

**Use your browser via MCP**

```
https://amish.your-app.com/sse
```

## Architecture

```
todo: mermaid diagram
```
