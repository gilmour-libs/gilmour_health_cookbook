user = node[:vars][:user]

ignore_host_path = File.join(node[:gilmour_health][:repo_path], 'bin')
ignore_host_binary = File.join(ignore_host_path, 'ignore_host')

directory ignore_host_path do
  recursive true
  mode '0755'
  action :create
  owner user
end

remote_file ignore_host_binary do
  backup 5
  source node[:gilmour_health][:ignore_host_binary]
  owner user
  mode '0755'
  action :create
  use_conditional_get true
  use_etag true
  use_last_modified true
end

params = { ignore_host: ignore_host_binary,
           redis_host: node[:gilmour_health][:redis_host] || '127.0.0.1',
           redis_port: node[:gilmour_health][:redis_port] || 6379 }

template File.join('/usr/local/bin', 'ignore_host') do
  action :create
  backup 5
  owner user
  mode '0755'
  source 'ignore_host.erb'
  variables params
end
