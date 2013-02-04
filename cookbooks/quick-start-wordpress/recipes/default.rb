#
# Cookbook Name:: quick-start-wordpress
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

db_node = search(:node,"role:database-server").first

node.set['wordpress']['db']['host'] = db_node.fqdn
node.set['wordpress']['db']['user'] = db_node.wordpress.db.user
node.set['wordpress']['db']['database'] = db_node.wordpress.db.database
node.set['wordpress']['db']['password'] = db_node.wordpress.db.password


include_recipe "mysql::client"
include_recipe "wordpress"
