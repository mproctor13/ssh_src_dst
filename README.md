# Description

Setup ssh tunnels between source and server.

# Requirements

## Platform:

* Ubuntu
* Debian
* Redhat
* Centos

## Cookbooks:

* openssh (Suggested but not required)

# Attributes

*No attributes defined*

# Recipes

* [ssh_src_dst::default](#ssh_src_dstdefault) - default recipe does nothing but include to get ssh_src and ssh_dst definitions.

## ssh_src_dst::default

default recipe does nothing but include to get ssh_src and ssh_dst definitions.

# Definitions

* [ssh_dst](#ssh_dst) - This definition sets up a user with authorized_keys to allow connections from ssh_src.
* [ssh_src](#ssh_src) - This definition sets up a user with ssh keys to make out bound ssh conection to ssh_dst.

## ssh_dst

  This definition sets up a user with authorized_keys to allow connections from ssh_src.


### Parameters

- dst_username: User on the destination, the user is automatically created.
- dst_group: User group that the should be set as User's primary group.
- dst_uid: User's uid so can set to 0 so that we can use privlaged ports.
- finder: Proc used to find source nodes, needs to return array of ssh pubkeys.

### Examples

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
## ssh_src

  This definition sets up a user with ssh keys to make out bound ssh conection to ssh_dst.


### Parameters

- src_username: User on the source, the user is automatically created.
- src_group: User group that the should be set as User's primary group.
- finder: Proc used to find source nodes, needs to return hash of hostname => hostkey.

### Examples

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

License & Authors
-----------------
- Author:: Michael Proctor-Smith (<mproctor13@gmail.com>)

```text
Copyright:: 2015, Michael Proctor-Smith

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
