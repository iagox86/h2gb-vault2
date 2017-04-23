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

# TODO: We're loading a file automatically to save trouble, eventually I'll need
# a better UI for this
test_file = File.dirname(__FILE__) + '/data/test.bmp'
memory = nil
File.open(test_file, 'rb') do |f|
  memory = H2gb::Vault::Memory.new(raw: f.read())
end
analyzer = H2gb::Vault::BitmapAnalyzer.new(memory)
analyzer.analyze()

# Enable cross-origin (TODO: Security implications, once that matters?)
enable(:cross_origin)
set(:protection, except: :json_csrf)
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


before do
  content_type(:json)
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

not_found() do
  output("Resource not found")
end

options("*") do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization"
  status(200)
end

get '/' do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end

get '/api/memory' do
  data = memory.get_all()
  return api_response(data)
end
