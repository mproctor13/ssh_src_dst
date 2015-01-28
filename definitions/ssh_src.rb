#
# Cookbook Name:: ssh_src_dst
# Definition:: ssh_src
#
# Author:: Michael Proctor-Smith (<mproctor13@gmail.com>)
#
# Copyright 2015, Michael Proctor-Smith
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

=begin
  #<
  This definition sets up a user with ssh keys to make out bound ssh conection to ssh_dst.

  @param src_username User on the source, the user is automatically created 
  @param src_group User group that the should be set as User's primary group
  @param finder Proc used to find source nodes, needs to return hash of hostname => hostkey
 
  @section Examples

      see ssh_tunnel cookbook for complete example or 

      node_find = Proc.new {
        keys = {}
        nodes = search(:node, "chef_environment:#{node.chef_environment}")
        nodes.each do |node|
          unless node['ssh_nodes']['ssh-hostkey'].nil?
            keys[node["fqdn"]] = node['ssh_tunnel']['ssh-hostkey']
          end
        end
        keys
      }
      ssh_src "ssh_nodes" do
        finder node_find
      end


  #>
=end

define :ssh_src do
  parent = params[:name]
  src_username = params[:src_username] ? params[:src_username] : "#{parent}src"
  src_grpname = params[:src_grpname] ? params[:src_grpname] : "daemon"
  cookbook = params[:cookbook] ? params[:cookbook] : "ssh_src_dst"
  
  node.default[parent] = {} if node[parent].nil?
  node.default[parent]['src_user'] = src_username
  node.default[parent]['src_group'] = src_grpname

  if node[parent]["nologin"].nil?
    node.set_unless[parent]["nologin"] = `which nologin`.strip  
  end

  user node[parent]['src_user'] do
    supports :manage_home => true
    gid node[parent]['src_group'] 
    shell node[parent]["nologin"]
    action :create
  end
  directory "/home/#{node[parent]['src_user']}/.ssh" do
    owner node[parent]['src_user']
    group node[parent]['src_group']
    mode "0700"
    recursive true
    action :create
  end
  execute "generate ssh key for #{node[parent]['src_user']}." do
    user node[parent]['src_user']
    creates "/home/#{node[parent]['src_user']}/.ssh/id_rsa.pub"
    command "ssh-keygen -t rsa -q -f /home/#{node[parent]['src_user']}/.ssh/id_rsa -P \"\""
  end

  # Save public key to chef-server 
  ruby_block 'node-save-pubkey' do
    block do
      node.set[parent]['ssh-pubkey'] = File.read("/home/#{node[parent]['src_user']}/.ssh/id_rsa.pub")
      node.save unless Chef::Config['solo']
    end
  end

  host_keys = {}
  if params[:finder].is_a? Proc
    host_keys = params[:finder].call
  end
  Chef::Log.error "host_keys=[#{host_keys}]"
  template "/home/#{node[parent]['src_user']}/.ssh/known_hosts" do
    cookbook cookbook
    source "known_hosts.erb"
    mode '0644'
    owner 'root'
    group 'root'
    variables :host_keys => host_keys
  end 
end

