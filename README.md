## Setup Guide

[![Deploy to DO](https://www.digitalocean.com/api/static-content/v1/images?src=https%3A%2F%2Fwww.deploytodo.com%2Fdo-btn-blue.svg&token=17b950890e7051c2a16c7739bad4f6d69e7773367b41d7b10e0e33a42a3e75b4)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/unitehenry/amish/tree/master)

```sh
doctl apps create --spec deploy.template.yaml
```

The one-click deploy will work out of the box, but here are some recommended ways to secure your deploy:

- [Guacamole Credentials](#guacamole-credentials)
- [Configure GitHub OAuth App](#configure-github-oauth-app)

### Guacamole Credentials

### Configure GitHub OAuth App

- https://github.com/settings/developers
- Callback URL: https://amish.you-app.com/auth/callback

## Usage

**Access your browser via browser**

```
https://amish.your-app.com/guacamole
```

**Use your browser via MCP**

```
https://amish.your-app.com/sse
```

## Architecture

```
todo: mermaid diagram
```
