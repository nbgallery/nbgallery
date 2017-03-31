# Creates VMs running the nb.gallery client image
# on DigitalOcean.
#
# You must have SSH keys configured on this machine
# to configure droplets.
class Droplet
  attr_reader :droplet, :client

  def self.client
    DropletKit::Client.new(
      access_token: ENV['DROPLET_TOKEN']
    )
  end

  def initialize(token=nil, **args)
    @client = Droplet.client

    if token.nil?
      create(**args)
    else
      @droplet = @client.droplets.all(tag_name: token).first

      if @droplet.is_a? String
        message = JSON.parse(@droplet)['message']
        raise message
      end
    end
  end

  def ip
    @droplet.networks.v4.first.ip_address
  end

  # creates a new droplet
  def create(**args)
    @droplet = @client.droplets.create(
      DropletKit::Droplet.new({
        name: SecureRandom.hex,
        size: '512mb',
        region: 'nyc3',
        image: 'docker-16-04',
        ssh_keys: @client.ssh_keys.all.map(&:fingerprint)
      }.merge(args))
    )

    # you can't find a droplet by name, so we tag it as well
    @client.tags.create(OpenStruct.new(name: token))

    @client.tags.tag_resources(
      name: token,
      resources: [
        {
          resource_id: @droplet.id,
          resource_type: 'droplet'
        }
      ]
    )

    # refresh the status
    until @droplet.status == 'active'
      sleep 1
      @droplet = @client.droplets.find id: @droplet.id
    end

    jupyter_deploy
  end

  def token
    @droplet.name
  end

  # deploys the jupyter service to the droplet
  def jupyter_deploy
    service_script = ERB.new(
      File.read(
        File.join(
          File.expand_path(__dir__),
          'jupyter.service'
        )
      )
    ).result binding

    begin
      Net::SCP.upload!(
        ip,
        'root',
        StringIO.new(service_script),
        '/etc/systemd/system/jupyter.service'
      )
    rescue Errno::ECONNREFUSED
      warn 'Could not connect to VM, retrying ...'
      retry
    end

    jupyter_start
  end

  def jupyter_start
    exec 'service jupyter start'
  end

  def jupyter_stop
    exec 'service jupyter stop'
  end

  def power_on
    @client.droplet_actions.power_on(
      droplet_id: @droplet.id
    )
  end

  def reboot
    exec 'shutdown -r now'
  end

  def power_off
    exec 'shutdown now'
  end

  def exec(command)
    Net::SSH.start(ip, 'root') do |ssh|
      output = ssh.exec!(command)
      return output unless output.empty?
    end
  end

  def destroy
    @client.droplets.delete id: @droplet.id
    @client.tags.delete name: token
  end
end
