# Chef starter.zip fetcher

This script, if called with the args <chef_server_url> <org> <username> <password>, will fetch a chef-starter.zip like
you might pull from the WebUI.

## MEGA WARNING

This will reset your user key on the chef server (cause it is generating a new private key for you). We're using this as part of a 
linked workstation setup for a demo, but generally you would only run this once.

