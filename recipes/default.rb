# Install / Upgrade UFW
package 'ufw' do
  action :upgrade
end

# Enable SSH by default
bash "open ufw for ssh traffic" do
  user "root"
  code <<-EOC
  ufw reset
  ufw default deny
  ufw allow 22
  EOC

  only_if { node['psw-simpleufw']['allow_ssh'] }
  notifies :run, 'execute[restart_ufw]', :delayed
end

# Enable rules via attributes
if node['psw-simpleufw']['rules']['allow']
  node['psw-simpleufw']['rules']['allow'].each do |rule|
    from_ip = rule['ip'] || 'any'
    to_protocol = rule['protocol'] || 'tcp'

    if rule['alias']
      shell_command = "ufw allow #{rule['alias']}"
    elsif rule['ip'] == 'any'
      shell_command = "ufw allow #{rule['port']}/#{to_protocol}"
    else
      shell_command = "ufw allow from #{from_ip} on port #{rule['port']}/#{to_protocol}"
    end

    bash shell_command do
      user "root"
      code shell_command

      notifies :run, 'execute[restart_ufw]', :delayed
    end
  end
end

# Restart ufw
execute 'restart_ufw' do
  user 'root'
  command <<-EOC
  ufw reload
  ufw --force enable
  EOC
  action :nothing
end
