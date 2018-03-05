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

  def self.all(&block)
    enum = Enumerator.new do |yielder|
      client.droplets.all.each do |droplet|
        yielder << Droplet.new(droplet.name)
      end
    end

    block.nil? ? enum : enum.each(&block)
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

  def token
    @droplet.name
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

    begin
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

      # configure the service with its token
      service_script = ERB.new(
        File.read(
          File.join(
            File.expand_path(__dir__),
            'jupyter.service'
          )
        )
      ).result binding

      begin
        # install the jupyter service
        Net::SCP.upload!(
          ip,
          'root',
          StringIO.new(service_script),
          '/etc/systemd/system/jupyter.service'
        )
      rescue Errno::ECONNREFUSED
        warn 'Could not connect to VM, retrying ...'
        sleep 1
        retry
      end

      # configure the service to start on boot
      exec 'systemctl enable jupyter.service'

      # start the service
      exec 'service jupyter start'
    rescue StandardError => ex
      warn "Droplet creation failed: #{ex.message}"
      destroy
    end
  end

  def exec(command)
    Net::SSH.start(ip, 'root') do |ssh|
      output = ssh.exec!(command)
      return output unless output.empty?
    end
  end

  def start
    @client.droplet_actions.power_on(
      droplet_id: @droplet.id
    )
  end

  def restart
    exec 'shutdown -r now'
  end

  def stop
    exec 'shutdown now'
  end

  def destroy
    @client.droplets.delete id: @droplet.id
    @client.tags.delete name: token
  end
end
