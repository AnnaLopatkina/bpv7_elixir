defmodule Bpv7.Bundle_Manager do
  use Timex
  use Bitwise
  @moduledoc """
  The bundle manager processes a bundle to be forwarded. This includes to parse the required packets and there fields into known data structures.
  With that completed the shipped crc32 checksums can be verified. One new block (previous node block) will be added to the bundle and two blocks (hop count block, bundle age block) will be adjusted.
  The bundle manager also serializes the bundle into the cbor format to be than transferred.
  """

  @doc """
  The forward_bundle function is the main function called by other modules. It is a script like execution of all steps necessary to get a ready to be forwarded bundle.
  Schedules the modified bundle in the BPA module with the destination endpoint id.

  Returns ':ok' or raises error for invalid crc or hop count limit reached.

  ## Examples
    iex> Bpv7.Bundle_Manager.forward_bundle(valid_bundle_array)
    :ok
  """
  def forward_bundle(bundle_array) do

    #decode cbor to array
    #bundle_array = decode_cbor_bundle(hexstring)

    #check the whole bundle crc
    check_bundle_crc(bundle_array)

    #hop count block increase
    bundle_array_hop = change_Hop_Count_Block(bundle_array)

    #insert previous node block
    bundle_array_previousNode = insert_previous_Node_Block(bundle_array_hop)

    #get source eid
    dest_eid = Enum.at(Enum.at(Enum.at(bundle_array_previousNode, 0), 3), 1)

    #schedule cbor binary bundle to source eid
    Bpv7.BPA.schedule_bundle(<<159>> <> bundleblock_binary(bundle_array_previousNode) <> <<255>>, dest_eid)

    :ok

  end

  @doc """
  The update_bundleAgeBlock function is called from BPA module shortly before the bundle is going to be sent. Therefore the timestamp inside the bundleAgeBlock is as up-to-date as possible.
  Inside the function the binary_bundle is parsed (cbor decoded), updated and serialized. The update part happens inside the update_bundle_Age_Block method.

  Returns 'binary bundle cbor encoded'.

  ## Examples

    iex> Bpv7.Bundle_Manager.update_bundleAgeBlock(<<cbor_binary>>)
    <<cbor_binary_updated_bundleAgeBlock>>
  """
  #insert bundleAgeBlock shortly before bundle is going to be sended
  def update_bundleAgeBlock(binary_bundle) do
    {:ok, bundle_array, ""} = CBOR.decode(binary_bundle)
    bundle_array_bundleAgeBlock = update_bundle_Age_Block(bundle_array)

    <<159>> <> bundleblock_binary(bundle_array_bundleAgeBlock) <> <<255>>
  end

  @doc """
  The bundleblock_binary recursive function converts an parsed bundle_array to the corresponding cbor binary without header and cbor stop code.

  ## Examples

    iex> Bpv7.Bundle_Manager.bundleblock_binary([PrimaryBlock[],CanonicalBlocks*[]])
    <<cbor_bundle_binary>>
  """
  def bundleblock_binary(bundlearray) do
    if length(bundlearray) > 1 do
      blockarray = Enum.at(bundlearray, 0)
      bundlearray_new = List.delete_at(bundlearray, 0)

      array_binary_nocrc(blockarray) <> bundleblock_binary(bundlearray_new)
    else
      blockarray = Enum.at(bundlearray, 0)

      array_binary_nocrc(blockarray)
    end
  end

  @doc """
  The check_bundle_crc recursive function checks all crc checksums for validity (primary- and canonicalblocks) and raises an error if its calculated values does not match the provided ones.

  ## Examples

    iex> Bpv7.Bundle_Manager.check_bundle_crc([PrimaryBlock[],CanonicalBlocks*[]])
    :ok
  """
  def check_bundle_crc(bundle_array) do
    #get primaryblock
    primaryblock = get_primary(bundle_array)

    #check primary crc
    if !check_crc_primary(primaryblock) do
      raise "primary crc not correct"
    end

    #delete primary block
    canonical_array = List.delete_at(bundle_array, 0)

    #check canonical crc
    if !check_canonical_crc_array(canonical_array) do
      raise "canonical checksums not correct"
    end
    :ok
  end

  @doc """
  Used inside the check_bundle_crc and is responsible for the canonical crc.
  """
  def check_canonical_crc_array(canonical_array) do
    if length(canonical_array) > 1 do
      canonical_block = get_canonical(canonical_array, 0)
      canonical_array_new = List.delete_at(canonical_array, 0)

      check_canonical_crc_array(canonical_array_new) && check_canonical_crc(canonical_block)
    else
      canonical_block = get_canonical(canonical_array, 0)

      check_canonical_crc(canonical_block)
    end
  end

  @doc """
  Used inside the check_bundle_crc and is responsible for the primary crc.
  """
  def check_crc_primary(primaryblock) do
    primaryarray = primary_to_array(primaryblock)
    primarybinary = array_binary(primaryarray)

    {set_crc, ""} = Integer.parse(primaryblock.crc, 16)
    calculated_crc = :crc32cer.nif(primarybinary)

    if set_crc == calculated_crc do

      true

    else

      false

    end

  end

  @doc """
  Used inside the check_bundle_crc and is responsible for the canonical crc.
  """
  def check_canonical_crc(canonicalblock) do
    canoncicalarray = canonical_to_array(canonicalblock)
    canonicalbinary = array_binary(canoncicalarray)

    {set_crc, ""} = Integer.parse(canonicalblock.crc, 16)
    calculated_crc = :crc32cer.nif(canonicalbinary)

    if set_crc == calculated_crc do

      true

    else

      IO.puts("Blockcrc = #{canonicalblock.crc} ; calculatedcrc = #{Integer.to_string(:crc32cer.nif(canonicalbinary), 16)}")
      false

    end
  end

  @doc """
  Function to parse the primary block of an decoded cbor bundlearray into the primary block datastructure.

  Returns 'Primaryblock'.
  """
  def get_primary(blockarray) do
    {:ok, crc_needed_bitstring} = Map.fetch(Enum.at(Enum.at(blockarray, 0), 8), :value)
    primaryblock = %Bpv7.Primary_Block{version: Enum.at(Enum.at(blockarray, 0), 0), bundle_control_flags: Enum.at(Enum.at(blockarray, 0), 1), crc_type: Enum.at(Enum.at(blockarray, 0), 2),
      destination: [Enum.at(Enum.at(Enum.at(blockarray, 0), 3), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 3), 1)],
      source_node: [Enum.at(Enum.at(Enum.at(blockarray, 0), 4), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 4), 1)],
      report_to: [Enum.at(Enum.at(Enum.at(blockarray, 0), 5), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 5), 1)],
      creation_time_stamp: [Enum.at(Enum.at(Enum.at(blockarray, 0), 6), 0), Enum.at(Enum.at(Enum.at(blockarray, 0), 6), 1)],
      lifetime: Enum.at(Enum.at(blockarray, 0), 7),
      crc: Base.encode16(crc_needed_bitstring)}

    primaryblock
  end

  @doc """
  Function to parse the canonical block with blocknumber of an decoded cbor bundlearray into the canonical block datastructure.

  Returns 'Canonicalblock'.
  """
  def get_canonical(blockarray, canonicalblocknumber) do
    {:ok, crc_needed_bitstring} = Map.fetch(Enum.at(Enum.at(blockarray, canonicalblocknumber), 5), :value)
    {:ok, specific_data_needed_bitstring_encoded} = Map.fetch(Enum.at(Enum.at(blockarray, canonicalblocknumber), 4), :value)
    specific_data_decoded = decode_specific_data(Enum.at(Enum.at(blockarray, canonicalblocknumber), 0), specific_data_needed_bitstring_encoded)
    canonicalblock = %Bpv7.Canonical_Block{block_type_code: Enum.at(Enum.at(blockarray, canonicalblocknumber), 0),
      block_number: Enum.at(Enum.at(blockarray, canonicalblocknumber), 1),
      block_control_flags: Enum.at(Enum.at(blockarray, canonicalblocknumber), 2),
      crc_type: Enum.at(Enum.at(blockarray, canonicalblocknumber), 3),
      block_type_specific_data: specific_data_decoded,
      crc: Base.encode16(crc_needed_bitstring)}

    canonicalblock
  end

  @doc """
  The methode decodes the nested cbor coding for the block specific data.

  Returns 'decoded specific data'.

  ## Examples

    iex> Bpv7.Bundle_Manager.decode_specific_data(blocktype, %CBOR.Tag{tag: :bytes, value: <<value>>})
    value
  """
  def decode_specific_data(blocktype, specific_data_needed_bitstring_encoded) do
    if blocktype == 1 do
      specific_data_needed_bitstring_encoded
    else
      {:ok, specific_data_decoded, ""} = CBOR.decode(specific_data_needed_bitstring_encoded)
      specific_data_decoded
    end
  end

  @doc """
  The method decode_cbor_bundle decodes a cbor encoded hexstring.

  Returns 'decoded cbor datastructures'

  ## Examples

    iex> Bpv7.decode_cbor_bundle("3287FE32CB82")
    [Primaryblock[], Canonicalblocks*[]]
  """
  def decode_cbor_bundle(hexstring) do
    {:ok, array, ""} = CBOR.decode(Base.decode16!(String.upcase(hexstring)))

    array
  end

  @doc """
  This method converts the intern primaryblock datastructure into an ordered array.
  """
  def primary_to_array (primaryblock) do
    primaryarray = [primaryblock.version, primaryblock.bundle_control_flags, primaryblock.crc_type, primaryblock.destination,
    primaryblock.source_node, primaryblock.report_to, primaryblock.creation_time_stamp, primaryblock.lifetime]

    primaryarray
  end

  @doc """
  This method converts the intern canonicalblock datastructure into an ordered array.
  """
  def canonical_to_array(canonicalblock) do
    canonicalarray = [canonicalblock.block_type_code, canonicalblock.block_number, canonicalblock.block_control_flags,
      canonicalblock.crc_type, canonical_to_array_specific_data(canonicalblock)]

    canonicalarray
  end

  @doc """
  This method implements the nested cbor encoding for canonical block specific data.
  """
  def canonical_to_array_specific_data(canonicalblock) do
    if canonicalblock.block_type_code == 1 do
      %CBOR.Tag{tag: :bytes, value: canonicalblock.block_type_specific_data}
    else
      %CBOR.Tag{tag: :bytes, value: CBOR.encode(canonicalblock.block_type_specific_data)}
    end
  end

  @doc """
  The array_binary methods encodes an block array to its cbor representation with header.
  Furthermore this function is needed to calculate the crc32 checksum. Therefore the array is appended with an crc value of 0.

  Returns 'cbor binary with crc32 of 0'
  """
  def array_binary(array) do
    cbor_array_header = Base.decode16!(Integer.to_string(0x80 ||| length(array) + 1, 16))

    array_bin = Enum.map(array, fn(field) -> CBOR.encode(field) end)

    array_bin_header = [cbor_array_header | array_bin]
    array_ready_crc = array_bin_header ++ [Base.decode16!("4400000000")]

    Enum.join(array_ready_crc)

  end

  @doc """
  The same function as array_binary but without the appended crc.

  Returns 'cbor binary'
  """
  def array_binary_nocrc(array) do
    cbor_array_header = Base.decode16!(Integer.to_string(0x80 ||| length(array), 16))

    array_bin = Enum.map(array, fn(field) -> CBOR.encode(field) end)

    array_bin_header = [cbor_array_header | array_bin]

    Enum.join(array_bin_header)
  end

  @doc """
  This function inserts the previous node block necessary for forwarding a bundle into the bundle array. The crc for the previous node block gets also calculated and appended.

  Returns 'bundlearray with previousNodeBlock'

  ## Examples

    iex> Bpv7.Bundle_Manager.insert_previous_Node_Block([Primaryblock[], Canonicalblock*[]]
    [Primaryblock[],Canonicalblock*[], PreviousNodeBlock[], PayloadBlock[]]
  """
  def insert_previous_Node_Block(bundlearray) do

    specific_data = "dtn://lawa.dtn"

    previousNodeBlock_array = [6, 4, 0, 2, %CBOR.Tag{tag: :bytes, value: CBOR.encode(specific_data)}]

    previous_node_binary = array_binary(previousNodeBlock_array)
    crc_new = %CBOR.Tag{tag: :bytes, value: <<:crc32cer.nif(previous_node_binary)::32>>}

    previousNodeBlock_array_crc = previousNodeBlock_array ++ [crc_new]

    List.insert_at(bundlearray, length(bundlearray) - 1, previousNodeBlock_array_crc)
  end

  @doc """
  This function updates the bundleAgeBlock for the forwarded bundle. It calculates the milliseconds elapsed since the bundle was created and insert it into the specific data.
  Calculates the new crc32 checksum.

  Returns 'bundlearray with updatedBundleAgeBlock'
  """
  def update_bundle_Age_Block(bundlearray) do

    bundleAgeBlock = get_canonical(bundlearray, 2)
    bundleAgeBlockArray = canonical_to_array(bundleAgeBlock)

    primaryBlock = get_primary(bundlearray)
    creation_milliseconds = Enum.at(primaryBlock.creation_time_stamp, 0)

    bpv7_epoch = "2000-01-01 00:00:00"
    bpv7_epoch_date = Timex.parse!(bpv7_epoch, "%Y-%m-%d %H:%M:%S", :strftime)
    bpv7_epoch_milliseconds = DateTime.to_unix(Timex.to_datetime(bpv7_epoch_date), :millisecond)

    specific_data = %CBOR.Tag{tag: :bytes, value: CBOR.encode(DateTime.to_unix(Timex.now(), :millisecond) - creation_milliseconds - bpv7_epoch_milliseconds)}

    bundleAgeBlockArray_edited = List.replace_at(bundleAgeBlockArray, 4, specific_data)

    bundleAgeBlockArray_edited_binary = array_binary(bundleAgeBlockArray_edited)
    crc_new = %CBOR.Tag{tag: :bytes, value: <<:crc32cer.nif(bundleAgeBlockArray_edited_binary)::32>>}

    bundleAgeBlockFinish = bundleAgeBlockArray_edited ++ [crc_new]

    List.replace_at(bundlearray, 2, bundleAgeBlockFinish)
  end

  @doc """
  This function updates the hopCountBlock inside the provided bundlearray. It checks wether the hop count limit is reached and if not it increments the hop count.
  A new crc32 checksum is calculated and updated.

  Returns 'bundlearray with updated hopCountBlock'
  """
  def change_Hop_Count_Block(bundlearray) do

    hopCountBlock = get_canonical(bundlearray, 1)
    hopCountBlockArray = canonical_to_array(hopCountBlock)

    {:ok, specific_data_encoded} = Map.fetch(Enum.at(hopCountBlockArray, 4), :value)
    {:ok, specific_data_decoded, ""} = CBOR.decode(specific_data_encoded)
    hopCountBlockArray_decoded = List.replace_at(hopCountBlockArray, 4, specific_data_decoded)

    hopLimit = Enum.at(Enum.at(hopCountBlockArray_decoded, 4), 0)
    hopCount = Enum.at(Enum.at(hopCountBlockArray_decoded, 4), 1)


    if hopCount < hopLimit do

      hopCountAndLimit = %CBOR.Tag{tag: :bytes, value: CBOR.encode([hopLimit, hopCount + 1])}
      updatedHopCountBlockArray = List.replace_at(hopCountBlockArray_decoded, 4, hopCountAndLimit)

      updatedHopCountBlockArray_bin = array_binary(updatedHopCountBlockArray)
      crc_new = %CBOR.Tag{tag: :bytes, value: <<:crc32cer.nif(updatedHopCountBlockArray_bin)::32>>}

      updatedHopCountBlockArray_crc = updatedHopCountBlockArray ++ [crc_new]

      List.replace_at(bundlearray, 1, updatedHopCountBlockArray_crc)

    else
    raise "hopLimit reached"
    end
  end

end
