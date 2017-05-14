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
require 'sinatra/cross_origin'

$LOAD_PATH.unshift File.expand_path('../../../../', __FILE__)

require 'h2gb/vault/memory/memory'
require 'h2gb/vault/analyzers/bitmap'

require 'h2gb/vault/api/error_handling'


# TODO: We're loading a file automatically to save trouble, eventually I'll need
# a better UI for this
test_file = File.dirname(__FILE__) + '/data/test.bmp'

memory = nil
File.open(test_file, 'rb') do |f|
  memory = H2gb::Vault::Memory.new(raw: f.read())
end

analyzer = H2gb::Vault::BitmapAnalyzer.new(memory)
analyzer.analyze()

updater = H2gb::Vault::Updater.new(memory: memory)

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
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  status(200)
end

get('/api/memories') do
  return {
    data: [{
      type: 'memory',
      id: '1',
      attributes: memory.get_all(),
    }]
  }
end

get('/api/memories/:id') do |id|
  return {
    data: {
      type: 'memory',
      id: id,
      attributes: memory.get_all(),
    }
  }
end

post('/api/memories/:id/update') do |id|
  updater.do(@params['updates'])

  return {
    'status': 200
  }
end

post('/api/memories/:id/undo') do |id|
  memory.undo()

  return {
    'status': 200
  }
end

post('/api/memories/:id/redo') do |id|
  memory.redo()

  return {
    'status': 200
  }
end

get('/') do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end
