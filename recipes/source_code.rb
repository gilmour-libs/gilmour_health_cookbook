#
# Cookbook Name:: gilmour_health
# Recipe:: default
#
# Copyright (C) 2015 Piyush Verma
#
# All rights reserved - Do Not Redistribute
#

pager_bag = data_bag_item('gilmour_health', 'pagerduty')
pagerduty_config = pager_bag[node.chef_environment] || pager_bag['_default']

user = node[:vars][:user]

%w( github.com bitbucket.org ).each do |host|
  ssh_known_hosts host do
    hashed true
  end
end

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
  notifies :restart, 'service[gilmour_health]'
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

cwd = File.join(node.gilmour_health.repo_path, 'current')

execute 'bundle_install' do
  command "su #{user} -c -l \"cd #{cwd} && bundle install\""
  environment 'BUNDLE_PATH' => bundle_path
  action :run
end

gem_package 'foreman' do
  action :install
end
