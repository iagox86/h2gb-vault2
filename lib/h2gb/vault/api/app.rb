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

configure() do
  # Enable cross-origin (TODO: Security implications, once that matters?)
  enable(:cross_origin)
  set(:allow_origin, :any)
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
  content_type('application/vnd.api+json')
  headers('Access-Control-Allow-Origin' => '*')
end

before(accepted_verbs: ['POST', 'PUT']) do
  begin
    @params = JSON.parse(request.body.read)
  rescue Exception => e # TODO: Use the right exception
    halt(400, output("Invalid JSON: " + e.to_s()))
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
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization"
  status(200)
end

get('/') do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end

get('/api/memories') do
  data = memory.get_all()

  return {
    data: [{
      type: 'memory',
      id: '1',
      attributes: data,
    }]
  }
end

get('/api/memories/1') do
  data = memory.get_all()

  return {
    data: {
      type: 'memory',
      id: '1',
      attributes: data,
    }
  }
end
