# encoding: ASCII-8BIT
##
# app.rb
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

require 'h2gb/vault/api/error_handling'
require 'h2gb/vault/api/workspaces'

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
  puts response.body
end

options("*") do
  headers("Allow" => "HEAD,GET,PUT,POST,DELETE,OPTIONS")
  headers('Access-Control-Request-Method' => "POST")
  headers('Access-Control-Allow-Headers' => "Content-Type")
  headers('Access-Control-Allow-Origin' => '*')
  status(200)
end

get('/') do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end
