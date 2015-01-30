#
# Cookbook Name:: ssh_src_dst
# Definition:: ssh_dst
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
  This definition sets up a user with authorized_keys to allow connections from ssh_src.

  @param dst_username User on the destination, the user is automatically created 
  @param dst_group User group that the should be set as User's primary group
  @param dst_uid User's uid so can set to 0 so that we can use privlaged ports
  @param finder Proc used to find source nodes, needs to return array of ssh pubkeys
 
  @section Examples

      see ssh_tunnel cookbook for complete example or 

      node_find = Proc.new {
        keys = []
        nodes = search(:node, "chef_environment:#{node.chef_environment}")
        nodes.each do |node|
          unless node['ssh_nodes']['ssh-pubkey'].nil?
            keys << node['ssh_tunnel']['ssh-pubkey']
          end
        end
        keys
      }
      ssh_dst "ssh_nodes" do
        dst_username 'appuser'
        dst_group 'appgroup'
        finder node_find
      end


  #>
=end

define :ssh_dst, :push_only => false do
  parent = params[:name]
  dst_username = params[:dst_username] ? params[:dst_username] : "#{parent}dst"
  dst_grpname = params[:dst_grpname] ? params[:dst_grpname] : "daemon"
  dst_uid = params[:dst_uid] ? params[:dstuid] : nil
  cookbook = params[:cookbook] ? params[:cookbook] : "ssh_src_dst"

  node.default[parent] = {} if node[parent].nil?
  node.default[parent]['dst_user'] = dst_username
  node.default[parent]['dst_group'] = dst_grpname

  if params[:push_only]
    ushell = "/usr/bin/rssh"
    #include_recipe "rssh::default"
    rssh_user node[parent]['dst_user'] do
      options "022:100010"
    end
  else
    if node[parent]["nologin"].nil?
      node.set_unless[parent]["nologin"] = `which nologin`.strip  
    end
    ushell = node[parent]["nologin"]
  end

  if dst_uid.nil?
    supports = {:manage_home => true}
  else
    supports = {:manage_home => true, :non_unique => true}
  end
  user node[parent]['dst_user'] do
    supports supports
    uid dst_uid unless dst_uid.nil?
    gid node[parent]['dst_group'] 
    shell ushell
    action :create
  end

  # Save host public key to chef-server 
  ruby_block 'node-save-hostkey' do
    block do
      node.set[parent]['ssh-hostkey'] = File.read("/etc/ssh/ssh_host_rsa_key.pub")
    end
  end

  allowed_keys = {}
  if params[:finder].is_a? Proc
    allowed_keys = params[:finder].call
  end

  if allowed_keys.count > 0
    directory "/home/#{node[parent]['dst_user']}/.ssh" do
      owner node[parent]['dst_user']
      group node[parent]['dst_group']
      mode "0700"
      recursive true
      action :create
    end
    template "/home/#{node[parent]['dst_user']}/.ssh/authorized_keys" do
      source "authorized_keys.erb"
      cookbook cookbook
      owner node[parent]['dst_user']
      group node[parent]['dst_group']
      mode "0600"
      variables :ssh_keys => allowed_keys
    end
  end
end

