# encoding: ASCII-8BIT
##
# workspaces.rb
# Created May, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# API functions for dealing with workspaces
##

require 'h2gb/vault/workspace'
require 'h2gb/vault/analyzers/bitmap'
require 'h2gb/vault/analyzers/code'

workspaces = {}
updaters = {}

# Pre-make some workspaces so we have test data and don't have to deal with
# creation (yet)
test_file = File.dirname(__FILE__) + '/data/test.bmp'
workspaces['1'] = H2gb::Vault::Workspace.new()
File.open(test_file, 'rb') do |f|
  workspaces['1'].transaction() do
    workspaces['1'].create_block(block_name: 'data', base_address: 0x0000, raw: f.read())
  end
end
analyzer = H2gb::Vault::BitmapAnalyzer.new(workspace: workspaces['1'])
analyzer.analyze()
updaters['1'] = H2gb::Vault::Updater.new(workspace: workspaces['1'])

test_file = File.dirname(__FILE__) + '/data/test.bin'
workspaces['2'] = H2gb::Vault::Workspace.new()
File.open(test_file, 'rb') do |f|
  workspaces['2'].transaction() do
    workspaces['2'].create_block(block_name: 'data', base_address: 0x0000, raw: f.read())
  end
end
analyzer = H2gb::Vault::CodeAnalyzer.new(workspace: workspaces['2'])
analyzer.analyze()
updaters['2'] = H2gb::Vault::Updater.new(workspace: workspaces['2'])

get('/api/workspaces') do
  results = []

  workspaces.each_pair do |id, workspace|
    results << {
      type: 'workspace',
      id: id,
      attributes: workspaces[id].get_all(),
    }
  end

  return results
end

get('/api/workspaces/:id') do |id|
  puts "id = %s" % id.to_s
  return {
    data: {
      type: 'workspace',
      id: id,
      attributes: workspaces[id].get_all(),
    }
  }
end

post('/api/workspaces/:id/update') do |id|
  updaters[id].do(@params['updates'])

  return {
    'status': 200
  }
end

post('/api/workspaces/:id/undo') do |id|
  workspaces[id].undo()

  return {
    'status': 200
  }
end

post('/api/workspaces/:id/redo') do |id|
  workspaces[id].redo()

  return {
    'status': 200
  }
end
