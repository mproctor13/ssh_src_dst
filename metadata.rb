name             "ssh_src_dst"
maintainer       "Michael P Proctor-Smith"
maintainer_email "mproctor13@gmail.com"
license          "Apache 2.0"
description      "Setup ssh tunnels between source and server."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w( ubuntu debian redhat centos ).each do |os|
  supports os
end

suggests "openssh"

