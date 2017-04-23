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

get '/' do
  return "Welcome to the h2gb-vault API! The requests are /api/*, you'll probably want to read the documentation :)"
end

get '/api/memory' do
  data = memory.get_all()
  #return YAML::dump(data)
  return data.to_json()
end
