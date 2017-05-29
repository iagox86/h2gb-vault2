# encoding: ASCII-8BIT
require 'test_helper'

require 'h2gb/vault/analyzers/code'

module H2gb
  module Vault
    class CodeTest < Test::Unit::TestCase
      def test_parsing()
        test_data = (
          "\x31\xc0" +     # xor eax, eax
          "\xb0\x46" +     # mov al, 70
          "\x31\xdb" +     # xor ebx, ebx
          "\x31\xc9" +     # xor ecx, ecx
          "\xcd\x80" +     # int 0x80
          "\xeb\x16" +     # jmp +21
          "\x5b"     +     # pop ebx
          "\x31\xc0" +     # xor eax, eax
          "\x88\x43\x07" + # mov [ebx+0x7], al
          "\x89\x5b\x08" + # mov [ebx+0x08], ebx
          "\x89\x43\x0c" + # mov [ebx+0x0c], eax
          "\xb0\x0b" +     # mov al, 0x0b
          "\x8d\x4b\x08" + # lea ecx, [ebx+0x08]
          "\x8d\x53\x0c" + # lea edx, [ebx+0x0c]
          "\xcd\x80" +     # int 0x80
          "\xe8\xe5\xff\xff\xff" +
          "/bin/sh"
        )

        @workspace = Workspace.new()
        @workspace.transaction() do
          @workspace.create_block(block_name: 'data', base_address: 0x0000, raw: test_data)
        end
        @analyzer = CodeAnalyzer.new(workspace: @workspace)
        @analyzer.analyze()

        assert_equal("xor eax, eax",                   @workspace.get_single(block_name: 'data', address: 0x0000)[:value])
        assert_equal("mov al, 0x46",                   @workspace.get_single(block_name: 'data', address: 0x0002)[:value])
        assert_equal("xor ebx, ebx",                   @workspace.get_single(block_name: 'data', address: 0x0004)[:value])
        assert_equal("xor ecx, ecx",                   @workspace.get_single(block_name: 'data', address: 0x0006)[:value])
        assert_equal("int 0x80",                       @workspace.get_single(block_name: 'data', address: 0x0008)[:value])
        assert_equal("jmp 0x22",                       @workspace.get_single(block_name: 'data', address: 0x000a)[:value])
        assert_equal("pop ebx",                        @workspace.get_single(block_name: 'data', address: 0x000c)[:value])
        assert_equal("xor eax, eax",                   @workspace.get_single(block_name: 'data', address: 0x000d)[:value])
        assert_equal("mov byte ptr [ebx + 7], al",     @workspace.get_single(block_name: 'data', address: 0x000f)[:value])
        assert_equal("mov dword ptr [ebx + 8], ebx",   @workspace.get_single(block_name: 'data', address: 0x0012)[:value])
        assert_equal("mov dword ptr [ebx + 0xc], eax", @workspace.get_single(block_name: 'data', address: 0x0015)[:value])
        assert_equal("mov al, 0xb",                    @workspace.get_single(block_name: 'data', address: 0x0018)[:value])
        assert_equal("lea ecx, dword ptr [ebx + 8]",   @workspace.get_single(block_name: 'data', address: 0x001a)[:value])
        assert_equal("lea edx, dword ptr [ebx + 0xc]", @workspace.get_single(block_name: 'data', address: 0x001d)[:value])
        assert_equal("int 0x80",                       @workspace.get_single(block_name: 'data', address: 0x0020)[:value])
        assert_equal("call 0xc",                       @workspace.get_single(block_name: 'data', address: 0x0022)[:value])
      end
    end
  end
end
