service_name = "gilmour_health"
user = node[:vars][:user]
source_dir = File.join(node[:gilmour_health][:repo_path], "current")
command = "foreman export upstart /etc/init -a #{service_name} -u #{user} -l /tmp"

log_file = File.join(source_dir, "log", "gilmour_health.log")

node.set.ds_logger.watch_files.gilmour_health = log_file

template File.join(source_dir, "Procfile") do
  action :create
  backup 5
  owner user
  source "procfile.erb"
  variables :log_file => log_file,
    :config_file => File.join(source_dir, "config", "config.yaml")
  notifies :run, 'execute[foreman_health_script]', :immediately
end

execute "foreman_health_script" do
  action :nothing
  command command
  cwd source_dir
end

service service_name do
  supports :status => true, :restart => true
  action [ :enable, :restart ]
  subscribes :restart, "execute[foreman_script]", :immediately
  restart_command "service #{service_name} restart"
  start_command "service #{service_name} start"
  status_command "service #{service_name} status"
  stop_command "service #{service_name} stop"
end
