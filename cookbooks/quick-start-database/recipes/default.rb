#
# Cookbook Name:: quick-start-database
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "mysql::server"

node.set['wordpress']['db']['user'] = 'wordpress'
node.set['wordpress']['db']['database'] = 'wordpressdb'
node.set['wordpress']['db']['password'] = secure_password

mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

mysql_database node['wordpress']['db']['database'] do
  connection mysql_connection_info
  action :create
  notifies :create, "ruby_block[save node data]", :immediately unless Chef::Config[:solo]
end

['localhost', '%', node['fqdn']].each do |db_host|
  mysql_database_user node['wordpress']['db']['user'] do
    connection mysql_connection_info
    password node['wordpress']['db']['password']
    database_name node['wordpress']['db']['database']
    host db_host
    action :grant
  end
end


# save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end
