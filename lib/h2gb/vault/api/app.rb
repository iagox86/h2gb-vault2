# encoding: ASCII-8BIT
##
# main.rb
# Created April, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# The main entrypoint for the API endpoint.
##

require 'base64'
require 'json'
require 'sinatra'

$LOAD_PATH.unshift File.expand_path('../../../../', __FILE__)

require 'h2gb/vault/workspace'
require 'h2gb/vault/analyzers/bitmap'
require 'h2gb/vault/analyzers/code'

require 'h2gb/vault/api/error_handling'


workspaces = {}
updaters = {}

test_file = File.dirname(__FILE__) + '/data/test.bmp'
workspaces['1'] = H2gb::Vault::Workspace.new()
File.open(test_file, 'rb') do |f|
  workspaces['1'].transaction() do
    workspaces['1'].create_block(block_name: 'data', base_address: 0x0000, raw: f.read())
  end
end
analyzer = H2gb::Vault::BitmapAnalyzer.new(workspaces['1'])
analyzer.analyze()
updaters['1'] = H2gb::Vault::Updater.new(workspace: workspaces['1'])

test_file = File.dirname(__FILE__) + '/data/test.bin'
workspaces['2'] = H2gb::Vault::Workspace.new()
File.open(test_file, 'rb') do |f|
  workspaces['2'].transaction() do
    workspaces['2'].create_block(block_name: 'data', base_address: 0x0000, raw: f.read())
  end
end
analyzer = H2gb::Vault::CodeAnalyzer.new(workspaces['2'])
analyzer.analyze()
updaters['2'] = H2gb::Vault::Updater.new(workspace: workspaces['2'])

configure() do
  set(:allow_methods, [:get, :post, :put, :delete, :options])

  # Helpers for before
  set(:accepted_verbs) do |*verbs|
    condition do
      verbs.any?{|v| v == request.request_method }
    end
  end

  set(:not_accepted_verbs) do |*verbs|
    condition do
      !verbs.any?{|v| v == request.request_method }
    end
  end
end

before do
  headers('Access-Control-Allow-Origin' => '*')
  content_type('application/vnd.api+json')
end

before(accepted_verbs: ['POST', 'PUT']) do
  begin
    @params = JSON.parse(request.body.read)
  rescue JSON::ParserError=> e
    halt(400, puts("Invalid JSON: " + e.to_s() + " :: " + request.body.read))
  end
end

before(not_accepted_verbs: ['OPTION']) do
  @UrlParams = params.dup()
end

after('/api/*') do
  response.body = JSON.pretty_generate(response.body)
end

options("*") do
  headers("Allow" => "HEAD,GET,PUT,POST,DELETE,OPTIONS")
  headers('Access-Control-Request-Method' => "POST")
  headers('Access-Control-Allow-Headers' => "Content-Type")
  headers('Access-Control-Allow-Origin' => '*')
  status(200)
end

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

get('/') do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end
