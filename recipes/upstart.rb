service_name = node.gilmour_health.service

user = node[:vars][:user]
repo_path = node.gilmour_health.repo_path

source_dir = File.join(repo_path, "current")
bundle_path = File.join(repo_path, 'shared', 'bundle')

command = "foreman export upstart /etc/init -a #{service_name} -u #{user} -l /tmp"

template File.join(source_dir, "Procfile") do
  action :create
  backup 5
  owner user
  source "procfile.erb"
  variables({
    bundle_path: bundle_path,
    config_file: File.join(source_dir, "config", "config.yaml")
  })
  notifies :run, 'execute[foreman_health_script]', :delayed
end

execute "foreman_health_script" do
  action :nothing
  command command
  cwd source_dir
  notifies :restart, "service[#{service_name}]", :delayed
end

service service_name do
  action :nothing
  supports status: true, restart: true
  restart_command "service #{service_name} restart"
  start_command "service #{service_name} start"
  status_command "service #{service_name} status"
  stop_command "service #{service_name} stop"
end
