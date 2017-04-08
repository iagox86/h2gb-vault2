require 'test_helper'

class H2gb::VaultTest < Test::Unit::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::H2gb::Vault::VERSION
  end
end
