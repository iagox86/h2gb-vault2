
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end
require 'test/unit'
require 'h2gb/vault'
require 'h2gb/vault/memory/memory_entry'

class TestHelper
  def self._get_raw(address:, length:)
    return (0..255).to_a()[address, length]
  end

  def self.test_entry(address:, length:, raw: nil, type: :type, value: "value", user_defined: {}, comment: nil, refs: {}, xrefs: {})
    return {
      address:      address,
      type:         type,
      value:        value,
      length:       length,
      user_defined: user_defined,
      comment:      comment,
      raw:          raw || self._get_raw(address: address, length: length),
      refs:         refs,
      xrefs:        xrefs,
    }
  end

  def self.test_memory_entry(address:, type: :type, value: 0, length:, user_defined: {}, comment: nil)
    return H2gb::Vault::Memory::MemoryEntry.new(address: address, type: type, value: value, length: length, user_defined: user_defined, comment: comment)
  end

  def self.test_entry_deleted(address:, raw:nil, xrefs: {})
    raw = raw || self._get_raw(address: address, length: 1)
    return {
      address:      address,
      type:         :uint8_t,
      value:        raw[0].ord(),
      length:       1,
      user_defined: {},
      comment:      nil,
      raw:          raw || self._get_raw(address: address, length: length),
      refs:         {},
      xrefs:        xrefs,
    }
  end

  def self.test_memory_entry_deleted(address:, raw:nil)
    raw = raw || self._get_raw(address: address, length: 1)

    return H2gb::Vault::Memory::MemoryEntry.new(address: address, type: :uint8_t, value: raw[0].ord, length: 1, user_defined: {}, comment: nil)
  end
end
