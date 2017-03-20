# Droplet Extension

You need two things to use the Droplet extension: 

1) An [API token from DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2) saved as `DROPLET_TOKEN` in `ENV` and 
2) [SSH configured to use DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)

Once configured, you can create a new droplet with the following command: 

```ruby 
droplet = Droplet.new
```

To get a handle to an existing droplet, just pass the dropet ID:

```ruby 
droplet = Droplet.new '123123'
```

## Jupyter Service

The nb.gallery client runs as the `jupyter` service on droplets. The service is automatically installed and started when droplets are created. This service runs on port 80 without authentication. nb.gallery authenticates users and then proxies the connection over HTTPS. This service is not recommended for use outside of nb.gallery. 

You can manually start, stop, or redeploy the servce:

```ruby 
droplet.jupyter_deploy
droplet.jupyter_start
droplet.jupyter_stop
```

The service will save state so the VM can be stopped or started without losing work in Jupyter. 

## VM Commands

You can control the VM with the following commands:

```ruby 
droplet.power_on
droplet.power_off
droplet.reboot
```

## SSH 

`exec` will execute an arbitrary SSH command:

```ruby 
puts droplet.exec('uptime')
```