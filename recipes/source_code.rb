#
# Cookbook Name:: gilmour_health
# Recipe:: default
#
# Copyright (C) 2015 Piyush Verma
#
# All rights reserved - Do Not Redistribute
#

service_name = node.gilmour_health.service
pager_bag = data_bag_item('gilmour_health', 'pagerduty')
pagerduty_config = pager_bag[node.chef_environment] || pager_bag['_default']

user = node[:vars][:user]

package 'git'

directory node[:gilmour_health][:repo_path] do
  recursive true
  mode '0755'
  action :create
  owner user
end

deploy_revision node[:gilmour_health][:repo_path] do
  user user
  repo node[:gilmour_health][:repo_url]
  revision node[:gilmour_health][:repo_revision]
  branch node[:gilmour_health][:repo_branch]
  shallow_clone true
  keep_releases 10
  action :deploy # or :rollback
  restart_command 'touch tmp/restart.txt'
  create_dirs_before_symlink %w(tmp public config deploy log)
  symlink_before_migrate({})
  # scm_provider Chef::Provider::Git
  # install dependencies
  notifies :restart, "service[#{service_name}]", :delayed
  notifies :run, 'execute[gilmour_health_deps]', :immediately
  notifies :create, "template[gilmour_health_upstart]", :immediately
end

params = { essential_topics: node[:gilmour_health][:essential_topics],
           listen_port: node[:gilmour_health][:listen_port],
           redis_host: node[:gilmour_health][:redis_host],
           redis_port: node[:gilmour_health][:redis_port],
           error_reporting_token: pagerduty_config['error_reporting_token'],
           health_reporting_token: pagerduty_config['health_reporting_token'] }

config_path = File.join(node[:gilmour_health][:repo_path], 'current', 'config',
                        'config.yaml')

template config_path do
  action :create
  backup 5
  owner user
  source 'config.yaml.erb'
  variables params
end

bundle_path = File.join(node.gilmour_health.repo_path, 'shared', 'bundle')
directory bundle_path do
  recursive true
  mode '0755'
  action :create
  owner user
end

repo_path = node.gilmour_health.repo_path
cwd = File.join(repo_path, 'current')
bundle_path = File.join(repo_path, 'shared', 'bundle')

execute 'gilmour_health_deps' do
  action :nothing
  command "su #{user} -c -l \"cd #{cwd} && bundle install --without development\""
  environment 'BUNDLE_PATH' => bundle_path
end

template 'gilmour_health_upstart' do
  backup 5
  owner user
  source "upstart.conf.erb"
  path "/etc/init/#{service_name}.conf"
  variables({
    user: user,
    path: cwd,
    bundle_path: bundle_path,
    config_file: File.join(cwd, "config", "config.yaml")
  })
  notifies :restart, "service[#{service_name}]", :delayed
end

%w(gilmour_health gilmour_health-manager gilmour_health-manager-1).each do |f|
  file "#{f}-upstart" do
    path "/etc/init/#{f}.conf"
    action :delete
  end
end

service service_name do
  action :nothing
  service_name service_name
  supports status: true, restart: true
  restart_command "service #{service_name} restart"
  start_command "service #{service_name} start"
  status_command "service #{service_name} status"
  stop_command "service #{service_name} stop"
end
