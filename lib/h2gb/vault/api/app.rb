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

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/analyzers/bitmap'
require 'h2gb/vault/analyzers/code'

require 'h2gb/vault/api/error_handling'


memories = {}
updaters = {}

test_file = File.dirname(__FILE__) + '/data/test.bmp'
File.open(test_file, 'rb') do |f|
  memories['1'] = H2gb::Vault::Memory.new(raw: f.read())
end
analyzer = H2gb::Vault::BitmapAnalyzer.new(memories['1'])
analyzer.analyze()
updaters['1'] = H2gb::Vault::Updater.new(memory: memories['1'])

test_file = File.dirname(__FILE__) + '/data/test.bin'
File.open(test_file, 'rb') do |f|
  memories['2'] = H2gb::Vault::Memory.new(raw: f.read())
end
analyzer = H2gb::Vault::CodeAnalyzer.new(memories['2'])
analyzer.analyze()
updaters['2'] = H2gb::Vault::Updater.new(memory: memories['2'])

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

get('/api/memories') do
  results = []

  memories.each_pair do |id, memory|
    results << {
      type: 'memory',
      id: id,
      attributes: memories[id].get_all(),
    }
  end

  return results
end

get('/api/memories/:id') do |id|
  puts "id = %s" % id.to_s
  return {
    data: {
      type: 'memory',
      id: id,
      attributes: memories[id].get_all(),
    }
  }
end

post('/api/memories/:id/update') do |id|
  updaters[id].do(@params['updates'])

  return {
    'status': 200
  }
end

post('/api/memories/:id/undo') do |id|
  memories[id].undo()

  return {
    'status': 200
  }
end

post('/api/memories/:id/redo') do |id|
  memories[id].redo()

  return {
    'status': 200
  }
end

get('/') do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end
