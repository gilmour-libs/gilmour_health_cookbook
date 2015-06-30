default[:gilmour_health][:repo_prefix] = "/opt/backend_manager"
default[:gilmour_health][:repo_path] = "#{node[:gilmour_health][:repo_prefix]}/health-bulletin"
default[:gilmour_health][:repo_url] = "http://github.com/gilmour-libs/health-bulletin.git"
default[:gilmour_health][:repo_branch] = "master"
default[:gilmour_health][:repo_revision] = "HEAD"
default[:gilmour_health][:redis_host] = "127.0.0.1"
default[:gilmour_health][:redis_port] = 6379

default[:vars][:user] = "ubuntu"