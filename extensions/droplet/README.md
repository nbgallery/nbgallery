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
droplet = Droplet.new 'id'
```

Droplet IDs are also the token for authenticating to their Jupyter service. 

## Managing Droplets

Use their respective methods to start, stop, restart or destroy Droplets:

```ruby 
droplet.start
droplet.stop
droplet.restart
droplet.destroy
```

## Jupyter Service

The Droplets run Jupyter as a service. The service is automatically installed and started when droplets are created. This service runs on port 80 with token authentication. To connect to the service, you'll need the Droplet IP and token:

```ruby 
ip = droplet.ip
token = droplet.token
```

On shutdown, the service will snapshot the docker image on shutdown and restore on startup.  

See `nginx.conf` for an example of automatically proxying users to their droplet. 

## Exec 

Use `exec` to execute an arbitrary command on the Droplet:

```ruby 
puts droplet.exec('uptime')
```

## Enumerating Droplets

You can get an enumerator using `Droplet.all`:

```ruby 
Droplet.all.count
first = Droplet.all.first
ips = Droplet.all.map &:ip
```