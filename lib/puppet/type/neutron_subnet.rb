Puppet::Type.newtype(:neutron_subnet) do

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Symbolic name for the subnet'
    newvalues(/.*/)
  end

  newproperty(:id) do
    desc 'The unique id of the subnet'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  newproperty(:cidr) do
    desc 'CIDR representing IP range for this subnet, based on IP version'
  end

  newproperty(:ip_version) do
    desc 'The IP version of the CIDR'
    newvalues('4', '6')
  end

  newproperty(:ipv6_ra_mode) do
    desc 'The IPv6 RA (Router Advertisement) mode'
    newvalues('dhcpv6-stateful', 'dhcpv6-stateless', 'slaac')
  end

  newproperty(:ipv6_address_mode) do
    desc 'The IPv6 Address mode'
    newvalues('dhcpv6-stateful', 'dhcpv6-stateless', 'slaac')
  end

  newproperty(:allocation_pools, :array_matching => :all) do
    desc <<-EOT
    Array of Sub-ranges of cidr available for dynamic allocation to ports.
    Syntax:["start=IPADDR,end=IPADDR", ...]
    EOT
    def insync?(is)
      is.to_set == should.to_set
    end
  end

  newproperty(:gateway_ip) do
    desc <<-EOT
    The default gateway provided by DHCP to devices in this subnet.  If set to
    '' then no gateway IP address will be provided via DHCP.
    EOT
  end

  newproperty(:enable_dhcp) do
    desc 'Whether DHCP is enabled for this subnet or not.'
    newvalues(/(t|T)rue/, /(f|F)alse/)
    munge do |v|
      v.to_s.capitalize
    end
  end

  newproperty(:host_routes, :array_matching => :all) do
    desc <<-EOT
    Array of routes that should be used by devices with IPs from this subnet
    (not including local subnet route).
    Syntax:["destination=CIDR,nexhop=IP_ADDR", ...]
    EOT
  end

  newproperty(:dns_nameservers, :array_matching => :all) do
    desc <<-EOT
    'Array of DNS name servers used by hosts in this subnet.'
    EOT
  end

  newproperty(:network_id) do
    desc 'A uuid identifying the network this subnet is associated with.'
  end

  newparam(:network_name) do
    desc 'The name of the network this subnet is associated with.'
  end

  newparam(:project_name) do
    desc 'The name of the project which will own the subnet.'
  end

  newproperty(:project_id) do
    desc 'A uuid identifying the project which will own the subnet.'
  end

  newparam(:tenant_name) do
    desc 'The name of the tenant which will own the subnet.(DEPRECATED)'
  end

  newproperty(:tenant_id) do
    desc 'A uuid identifying the tenant which will own the subnet.(DEPRECATED)'
  end

  autorequire(:anchor) do
    ['neutron::service::end']
  end

  autorequire(:keystone_tenant) do
    if self[:tenant_name]
      [self[:tenant_name]]
    else
      [self[:project_name]] if self[:project_name]
    end
  end

  autorequire(:neutron_network) do
    [self[:network_name]] if self[:network_name]
  end

  validate do
    if self[:ensure] != :present
      return
    end

    if ! self[:cidr]
      raise(Puppet::Error, 'Please provide a valid CIDR')
    end

    if ! (self[:network_id] || self[:network_name])
      raise(Puppet::Error, <<-EOT
A value for one of network_name or network_id must be provided.
EOT
            )
    end

    if self[:network_id] && self[:network_name]
      raise(Puppet::Error, <<-EOT
Please provide a value for only one of network_name and network_id.
EOT
            )
    end

    if self[:tenant_id]
      warning('The tenant_id property is deprecated. Use project_id.')
    end
    if self[:tenant_name]
      warning('The tenant_name property is deprecated. Use project_name.')
    end

    project_id = self[:tenant_id] or self[:project_id]
    project_name = self[:tenant_name] or self[:project_name]
    if project_id && project_name
      raise(Puppet::Error, <<-EOT
Please provide a value for only one of project_name and project_id.
EOT
            )
    end

    if (self[:ipv6_ra_mode] || self[:ipv6_address_mode]) && String(self[:ip_version]) != '6'
      raise(Puppet::Error, <<-EOT
ipv6_ra_mode and ipv6_address_mode can only be used with ip_version set to '6'
EOT
           )
    end
  end

end
