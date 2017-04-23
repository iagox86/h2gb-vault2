##
# error_handling.rb
# Created April, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# A class to install a nice JSON-based error handler. Reference:
#
# http://hawkins.io/2013/06/error-handling-in-sinatra-apis/
##

require 'json'

configure() do
  set(:raise_errors, true)
  set(:show_exceptions, false)
end

not_found() do
  status(404)
  return {
    errors: [{
      status: 404,
      title: "Not found",
    }]
  }
end

class ExceptionHandling
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      return @app.call(env)
    rescue Exception => e
      response = {
        errors: [{
          status: 500,
          title: e.to_s,
          detail: e.backtrace,
        }]
      }

      [500, {'Content-Type' => 'application/vnd.api+json'}, [JSON.pretty_generate(response)]]
    end
  end
end
use(ExceptionHandling)
