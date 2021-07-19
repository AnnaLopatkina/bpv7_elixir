defmodule Bundlemanager_test do
  use ExUnit.Case
  doctest Bpv7

  test "decode_hexstring" do
    bundle_array = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")
    assert is_list(bundle_array) == true
  end

  test "check_crc" do
    bundle_array = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")
    assert Bpv7.Bundle_Manager.check_bundle_crc(bundle_array) == :ok

    bundle_array_false = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26eff")
    assert_raise RuntimeError, "canonical checksums not correct", fn  ->
      Bpv7.Bundle_Manager.check_bundle_crc(bundle_array_false)
    end

    bundle_array_primary_false = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044c201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")
    assert_raise RuntimeError, "primary crc not correct", fn  ->
      Bpv7.Bundle_Manager.check_bundle_crc(bundle_array_primary_false)
    end
  end

end
