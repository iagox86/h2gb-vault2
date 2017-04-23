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

class ExceptionHandling
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      return @app.call(env)
    rescue Exception => e
      response = JSON.pretty_generate({
        message: e.to_s(),
        backtrace: e.backtrace(),
      })

      [500, {'Content-Type' => 'application/json'}, [response]]
    end
  end
end
use(ExceptionHandling)
