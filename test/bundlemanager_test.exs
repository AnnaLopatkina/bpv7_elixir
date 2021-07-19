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

  test "hop_count_block" do
    bundle_array = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")
    hopCountBlock = Bpv7.Bundle_Manager.get_canonical(bundle_array, 1)
    hopCountBlockArray = Bpv7.Bundle_Manager.canonical_to_array(hopCountBlock)

   {:ok, specific_data_encoded} = Map.fetch(Enum.at(hopCountBlockArray, 4), :value)
   {:ok, specific_data_decoded, ""} = CBOR.decode(specific_data_encoded)
    hop_limit = Enum.at(specific_data_decoded, 0)
    hop_count = Enum.at(specific_data_decoded, 1)

    bundle_array_updated = Bpv7.Bundle_Manager.change_Hop_Count_Block(bundle_array)
    hopCountBlock = Bpv7.Bundle_Manager.get_canonical(bundle_array_updated, 1)
    hopCountBlockArray = Bpv7.Bundle_Manager.canonical_to_array(hopCountBlock)

    {:ok, specific_data_encoded} = Map.fetch(Enum.at(hopCountBlockArray, 4), :value)
    {:ok, specific_data_decoded, ""} = CBOR.decode(specific_data_encoded)
   hop_limit_updated = Enum.at(specific_data_decoded, 0)
    hop_count_updated = Enum.at(specific_data_decoded, 1)

    assert hop_limit == hop_limit_updated
    assert hop_count + 1 == hop_count_updated
  end

  test "hop_count_block fail" do
    bundle_array = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024582181e181e4487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")

    assert_raise RuntimeError, "hopLimit reached", fn  ->
    Bpv7.Bundle_Manager.change_Hop_Count_Block(bundle_array)
    end
  end

  test "insert_previous_node_block" do
    bundle_array = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")
    bundle_array_previousNodeBlock = Bpv7.Bundle_Manager.insert_previous_Node_Block(bundle_array)
    blocktype = Enum.at(Enum.at(bundle_array_previousNodeBlock, length(bundle_array_previousNodeBlock)-2), 0)

    assert length(bundle_array_previousNodeBlock) == 5
    assert blocktype == 6
  end

  test "bundle_age_block" do
    bundle_binary_updated = Bpv7.Bundle_Manager.update_bundleAgeBlock(Base.decode16!(String.upcase("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")))
    {:ok, bundle_array_updated, ""} = CBOR.decode(bundle_binary_updated)
    blocktype = Enum.at(Enum.at(bundle_array_updated, 2), 0)
    {:ok, milliseconds_encoded} = Map.fetch(Enum.at(Enum.at(bundle_array_updated, 2), 4), :value)
    {:ok, milliseconds_decoded, ""} = CBOR.decode(milliseconds_encoded)

    assert blocktype == 7
    assert milliseconds_decoded > 0
  end

  test "bundle_binary" do
    bundle_array = Bpv7.Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009e3a0b75cf031a000493e044b201c5f4860a0200024482181e004487d25ff88607030002410044a0a52ecd86010100024c48656c6c6f20576f726c6421447585c26dff")

    bundle_binary = <<159>> <> Bpv7.Bundle_Manager.bundleblock_binary(bundle_array) <> <<255>>

    {:ok, bundle_array_dec, ""} = CBOR.decode(bundle_binary)

    assert bundle_array_dec == bundle_array
  end
end
