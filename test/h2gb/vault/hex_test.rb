require 'test_helper'

require 'h2gb/vault/hex'

class H2gb::Vault::HexTestToS < Test::Unit::TestCase
  def test_empty_string()
    str = H2gb::Vault::Hex.to_s('')
    assert_equal('', str)
  end

  def test_one_character_string()
    str = H2gb::Vault::Hex.to_s('A')
    assert_equal('00000000  41                                                A', str)
  end

  def test_sixteen_character_string()
    str = H2gb::Vault::Hex.to_s('AAAAAAAAAAAAAAAA')
    assert_equal('00000000  41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41   AAAAAAAAAAAAAAAA', str)
  end

  def test_more_than_sixteen()
    str = H2gb::Vault::Hex.to_s('AAAAAAAAAAAAAAAAAAAA')
    assert_equal("00000000  41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41   AAAAAAAAAAAAAAAA\n" +
                 "00000010  41 41 41 41                                       AAAA", str)
  end

  def test_null_bytes()
    str = H2gb::Vault::Hex.to_s("A\0A\0A")
    assert_equal('00000000  41 00 41 00 41                                    A.A.A', str)
  end

  def test_newlines()
    str = H2gb::Vault::Hex.to_s("A\nA\nA")
    assert_equal('00000000  41 0a 41 0a 41                                    A.A.A', str)
  end

  def test_exactly_thirty_two()
    str = H2gb::Vault::Hex.to_s('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
    assert_equal("00000000  41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41   AAAAAAAAAAAAAAAA\n" +
                 "00000010  41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41   AAAAAAAAAAAAAAAA", str)
  end

  def test_indent()
    str = H2gb::Vault::Hex.to_s('A', indent: 1)
    assert_equal(' 00000000  41                                                A', str)
  end

  def test_indent_two_lines()
    str = H2gb::Vault::Hex.to_s('AAAAAAAAAAAAAAAAAAAA', indent: 2)
    assert_equal("  00000000  41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41   AAAAAAAAAAAAAAAA\n" +
                 "  00000010  41 41 41 41                                       AAAA", str)
  end

  def test_indent_with_sixteen_characters()
    str = H2gb::Vault::Hex.to_s('AAAAAAAAAAAAAAAA', indent: 2)
    assert_equal('  00000000  41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41   AAAAAAAAAAAAAAAA', str)
  end
end
