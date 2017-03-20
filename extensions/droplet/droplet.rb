require 'net/scp'
require 'net/ssh'
require 'droplet_kit'

# Creates VMs running the nb.gallery client image
# on DigitalOcean.
#
# You must have SSH keys configured on this machine
# to configure droplets.
class Droplet
  attr_reader :droplet, :client

  def initialize(id: nil, **args)
    @client = DropletKit::Client.new(
      access_token: ENV['DROPLET_TOKEN']
    )

    if id.nil?
      create(**args)
    else
      @droplet = @client.droplets.find id: id

      if @droplet.is_a? String
        message = JSON.parse(@droplet)['message']
        raise message
      end
    end
  end

  # creates a new droplet
  def create(**args)
    @droplet = @client.droplets.create(
      DropletKit::Droplet.new({
        name: SecureRandom.hex(6),
        size: '512mb',
        region: 'nyc3',
        image: '23441953', # Docker 17.03.0-ce on 16.04
        ssh_keys: @client.ssh_keys.all.map(&:fingerprint)
      }.merge(args))
    )

    # refresh the status
    until @droplet.status == 'active'
      sleep 1
      @droplet = @client.droplets.find id: @droplet.id
    end

    jupyter_deploy
  end

  # deploys the jupyter service to the droplet
  def jupyter_deploy
    ip = @droplet.networks.v4.first.ip_address

    service_script = File.join(
      File.expand_path(__dir__),
      'jupyter.service'
    )

    Net::SCP.upload!(
      ip,
      'root',
      service_script, '/etc/systemd/system/'
    )

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
    ip = @droplet.networks.v4.first.ip_address

    Net::SSH.start(ip, 'root') do |ssh|
      output = ssh.exec!(command)
      return output unless output.empty?
    end
  end

  def destroy
    @client.droplets.delete id: @droplet.id
  end
end
