defmodule Bundle_Manager do
  use Timex
  use Bitwise
  @moduledoc false

  #Comands:
  #bundle = Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009db3c6e53f121a000493e044f42e713e860a0200014482181e00423d78860703000141004237ed86010100014c48656c6c6f20576f726c64214204a7ff")
  #primary = Bundle_Manager.get_primary(bundle)
  #primaryarray = Bundle_Manager.primary_to_array(primary)
  #binary = Bundle_Manager.primaryarray_binary(primaryarray)


  def get_primary(blockarray) do
    {:ok, crc_needed_bitstring} = Map.fetch(Enum.at(Enum.at(blockarray, 0), 8), :value)
    primaryblock = %Primary_Block{version: Enum.at(Enum.at(blockarray, 0), 0), bundle_control_flags: Enum.at(Enum.at(blockarray, 0), 1), crc_type: Enum.at(Enum.at(blockarray, 0), 2),
      destination: [Enum.at(Enum.at(Enum.at(blockarray, 0), 3), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 3), 1)],
      source_node: [Enum.at(Enum.at(Enum.at(blockarray, 0), 4), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 4), 1)],
      report_to: [Enum.at(Enum.at(Enum.at(blockarray, 0), 5), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 5), 1)],
      creation_time_stamp: [Enum.at(Enum.at(Enum.at(blockarray, 0), 6), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 6), 1)],
      lifetime: Enum.at(Enum.at(blockarray, 0), 7),
      crc: Base.encode16(crc_needed_bitstring)}

    primaryblock
  end

  def get_canonical(blockarray, canonicalblocknumber) do
    {:ok, crc_needed_bitstring} = Map.fetch(Enum.at(Enum.at(blockarray, canonicalblocknumber), 5), :value)
    {:ok, specific_data_needed_bitstring_encoded} = Map.fetch(Enum.at(Enum.at(blockarray, canonicalblocknumber), 4), :value)
    {:ok, specific_data_decoded, ""} = CBOR.decode(specific_data_needed_bitstring_encoded)
    canonicalblock = %Canonical_Block{block_type_code: Enum.at(Enum.at(blockarray, 0), 0),
      block_number: Enum.at(Enum.at(blockarray, 0), 1),
      block_control_flags: Enum.at(Enum.at(blockarray, 0), 2),
      crc_type: Enum.at(Enum.at(blockarray,0 ), 3),
      block_type_specific_data: specific_data_decoded,
      crc: Base.encode16(crc_needed_bitstring)}

    canonicalblock
  end

  def decode_cbor_bundle(hexstring) do
    {:ok, array, ""} = CBOR.decode(Base.decode16!(String.upcase(hexstring)))

    array
  end

  def primary_to_array (primaryblock) do
    primaryarray = [primaryblock.version, primaryblock.bundle_control_flags, primaryblock.crc_type, primaryblock.destination,
    primaryblock.source_node, primaryblock.report_to, primaryblock.creation_time_stamp, primaryblock.lifetime]

    primaryarray
  end

  def canonical_to_array(canonicalblock) do
    canonicalarray = [canonicalblock.block_type_code, canonicalblock.block_number, canonicalblock.block_control_flags,
      canonicalblock.crc_type, canonicalblock.block_type_specific_data, canonicalblock.crc]

    canonicalarray
  end

  def primaryarray_binary (primaryarray) do
    cbor_array_header = Base.decode16!(Integer.to_string(0x80 ||| length(primaryarray) + 1, 16))

    #for field <- primaryarray do
    #  CBOR.encode(field)
    #end

    primaryarray_bin = Enum.map(primaryarray, fn(field) -> CBOR.encode(field) end)

    first_array = [cbor_array_header | primaryarray_bin]
    array_ready_crc = first_array ++ [Base.decode16!("4400000000")]

    Enum.join(array_ready_crc)

  end

  def check_crc_primary(primaryblock) do
    primaryarray = primary_to_array(primaryblock)
    primarybinary = primaryarray_binary(primaryarray)

    if primaryblock.crc == Integer.to_string(:crc32cer.nif(primarybinary), 16) do

      true

      else

      false

      end

  end

  #def create_previous_Node_Block() do
    #previousNodeBlock = %Canonical_Block{block_type_code: 10, block_number: ,
      #block_control_flags: , crc_type: , block_type_specific_data:  , crc:}

    #previousNodeBlock
  #end

  def change_Hop_Count_Block(bundlearray) do

    hopCountBlock = get_canonical(bundlearray, 1)
    hopCountBlockArray = canonical_to_array(hopCountBlock)

    hopLimit = Enum.at(Enum.at(hopCountBlockArray, 4), 0)
    hopCount = Enum.at(Enum.at(hopCountBlockArray, 4), 1)


    if hopCount < hopLimit do

      hopCountAndLimit = [hopLimit, hopCount + 1]
      updatedHopCountBlockArray = List.replace_at(hopCountBlockArray, 4, hopCountAndLimit)

      updatedHopCountBlockArray

    else
    :false
    end
  end

end
