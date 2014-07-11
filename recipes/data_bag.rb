#
# Cookbook Name:: user
# Recipe:: data_bag
#
# Copyright 2011, Fletcher Nichol
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

# Look for user definitions in data_bags/[BAG]/*.json
# and group definitions in data_bags/[BAG]/*.json,
# where [BAG] is named in this node attribute.
# (default group_bag = 'users')
group_bag = node['user']['group_data_bag_name']

# Fetch the group array from the node's attribute hash. If a subhash is
# desired (ex. node['base']['user_groups']), then set:
#
#     node['user']['group_array_node_attr'] = "base/user_groups"
# (default group_array = 'groups')
group_array = node
node['user']['group_array_node_attr'].split("/").each do |hash_key|
  group_array = group_array.send(:[], hash_key)
end

# only manage the subset of groups defined
Array(group_array).each do |i|
  g = data_bag_item(group_bag, i.gsub(/[.]/, '-'))
  groupname = g['groupname'] || g['id']

  # Don't remove groups yet, since we may need to remove users first.
  if (g['action'].nil? || (g['action'] != 'remove'))
    group groupname do
      %w{gid}.each do |attr|
        send(attr, g[attr]) if g[attr]
      end          
      action g['action'].to_sym if g['action']
    end
  end
end

# Look for user definitions in data_bags/[BAG]/*.json
# and group definitions in data_bags/[BAG]/groups/*.json,
# where [BAG] is named in this node attribute.
# (default bag = 'users')
bag = node['user']['data_bag_name']
on_group_missing = node['user']['on_group_missing']

# Fetch the user array from the node's attribute hash. If a subhash is
# desired (ex. node['base']['user_accounts']), then set:
#
#     node['user']['user_array_node_attr'] = "base/user_accounts"
# (default user_array = 'users')
user_array = node
node['user']['user_array_node_attr'].split("/").each do |hash_key|
  user_array = user_array.send(:[], hash_key)
end

groups = {}

# only manage the subset of users defined
Array(user_array).each do |i|
  u = data_bag_item(bag, i.gsub(/[.]/, '-'))
  username = u['username'] || u['id']

  user_account username do
    %w{comment uid gid home shell password system_user manage_home create_group
        ssh_keys ssh_keygen non_unique }.each do |attr|
      send(attr, u[attr]) if u[attr]
    end
    action Array(u['action']).map { |a| a.to_sym } if u['action']
  end

  # Don't try to add user to groups if we are removing user
  if (u['action'].nil? || (u['action'] != 'remove'))
    unless u['groups'].nil?
      u['groups'].each do |groupname|
        group groupname do
          members username
          append true
        end
      end
    end
  end
end

# Now try to remove groups (since users would now have been removed)
# only manage the subset of groups defined
Array(group_array).each do |i|
  g = data_bag_item(group_bag, i.gsub(/[.]/, '-'))
  groupname = g['groupname'] || g['id']

  unless (g['action'].nil? || (g['action'] != 'remove'))
    group groupname do
      %w{gid}.each do |attr|
        send(attr, g[attr]) if g[attr]
      end          
      action g['action'].to_sym if g['action']
    end
  end
end

