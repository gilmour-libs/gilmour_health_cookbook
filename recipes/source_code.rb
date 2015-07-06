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

ssh_known_hosts_entry 'bitbucket.org'
ssh_known_hosts_entry 'github.com'

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
  create_dirs_before_symlink  %w{tmp public config deploy log}
  symlink_before_migrate({})
  # scm_provider Chef::Provider::Git
  # install dependencies
  notifies :restart, 'service[gilmour_health]'
end

params = { essential_topics: node[:gilmour_health][:essential_topics],
           redis_host: node[:gilmour_health][:redis_host],
           redis_port: node[:gilmour_health][:redis_port],
           error_reporting_token: pagerduty_config['error_reporting_token'],
           health_reporting_token: pagerduty_config['health_reporting_token'] }

template File.join(node[:gilmour_health][:repo_path], 'current', 'config', 'config.yaml') do
  action :create
  backup 5
  owner user
  source 'config.yaml.erb'
  variables params
end

env = { 'HOME' => "/home/#{user}", 'USER' => user }
execute 'gilmour_health_bundle_update' do
  user user
  command 'bash -c -l bundle update'

  cwd "#{node[:gilmour_health][:repo_path]}/current"
  action :run
  environment env
end

execute 'gilmour_health_bundle_install' do
  user user
  command ['bash -c -l bundle install',
           '--gemfile #{node[:gilmour_health][:repo_path]}/current/Gemfile',
           '--path #{node[:gilmour_health][:repo_path]}/shared/bundle'
          ].join(' ')

  cwd "#{node[:gilmour_health][:repo_path]}/current"
  action :run
  environment env
end

gem_package 'foreman' do
  action :install
end
