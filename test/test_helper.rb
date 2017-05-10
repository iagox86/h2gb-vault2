
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

class TestHelper
  def self.test_entry(address:, type: :type, value: "value", length:, refs: {}, user_defined: { test: 'hi' }, comment: 'bye', raw:, xrefs: {})
    return {
      address:      address,
      type:         type,
      value:        value,
      length:       length,
      refs:         refs,
      user_defined: user_defined,
      comment:      comment,
      raw:          raw,
      xrefs:        xrefs,
    }
  end

  def self.test_entry_deleted(address:, raw:, xrefs: {})
    return {
      address:      address,
      type:         :uint8_t,
      value:        raw[0],
      length:       1,
      refs:         {},
      user_defined: {},
      comment:      nil,
      raw:          raw,
      xrefs:        xrefs,
    }
  end
end

require 'h2gb/vault'

require 'test/unit'
