## Setup Guide

1. [Obtain a Virtual Machine](#obtain-a-virtual-machine)
2. [Setup DNS Record](#dns-record)
3. [Configure GitHub OAuth App](#configure-github-oauth-app)
4. [Install Script](#install-script)
5. [Install Wizard](#install-wizard)

### Obtain a Virtual Machine

- Ubuntu-24.04
- Static Public IP Address

### DNS Record

```
amish.your-app.com. 25  IN  A   <vm_static_public_ip>
```

### Configure GitHub OAuth App

- https://github.com/settings/developers
- Callback URL: https://amish.you-app.com/auth/callback

### Install Script

```sh
# Download install script
curl -sSL https://raw.githubusercontent.com/unitehenry/amish/master/install.sh -o /tmp/install.sh

# Run install script on virtual machine
bash /tmp/install.sh
```

### Install Wizard

- Guacamole Username / Password
- GitHub OAuth Client ID / Client Secret
- GitHub Username Whitelist
- GitHub Host -> https://amish.you-app.com
- Nginx Server Name -> amish.you-app.com

## Usage

```
# Access your browser in the browser
https://amish.your-app.com/guacamole

# Use your browser via MCP
https://amish.your-app.com/sse
```

## Architecture

```
todo: mermaid diagram
```

## Development

If you just want to run the service and don't want to enable GitHub OAuth, SSL, etc, then just download and install without the setup wizard.

```sh
# Download install script
curl -sSL https://raw.githubusercontent.com/unitehenry/amish/master/install.sh -o /tmp/install.sh

# Run install script
WIZARD=0 bash /tmp/install.sh

# Connect directly
http://127.0.0.1/guacamole
http://127.0.0.1/sse
```
