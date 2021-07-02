defmodule Bundle_Manager do
  use Timex
  use Bitwise
  @moduledoc false
"""

  def check_connection() do
    if untereschranke <= Timex.now <= obereschranke do
      forward_bundle_cla()
      else
      Schedule_Forwarding.Periodically.schedule_work(untereschranke - Timex.now())
    end
  end

  def forward_bundle_cla() do
    #send modified bundle to cla
  end

  def serialize_bundle do

  end

  Comands:
  bundle = Bundle_Manager.decode_cbor_bundle("9f890700028201722f2f632e64746e2f62756e646c6573696e6b8201672f2f612e64746e820100821b0000009df6c9e5d1011a000493e044ca8897ea860a0200014482181e00423d78860703000141004237ed86010100014c48656c6c6f20576f726c64214204a7ff")
  primary = Bundle_Manager.get_primary(bundle)
  primaryarray = Bundle_Manager.primary_to_array(primary)
  binary = Bundle_Manager.primaryarray_binary(primaryarray)
  
"""

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

  def decode_cbor_bundle(hexstring) do
    {:ok, array, ""} = CBOR.decode(Base.decode16!(String.upcase(hexstring)))

    array
  end

  def primary_to_array (primaryblock) do
    primaryarray = [primaryblock.version, primaryblock.bundle_control_flags, primaryblock.crc_type, primaryblock.destination,
    primaryblock.source_node, primaryblock.report_to, primaryblock.creation_time_stamp, primaryblock.lifetime]

    primaryarray
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
    checksum = primaryblock.crc

    primaryarray = primary_to_array(primaryblock)
    primarybinary = primaryarray_binary(primaryarray)

    IO.puts "CRC berechnet: #{Integer.to_string(:crc32cer.nif(primarybinary), 16)}"
    IO.puts "CRC erhalten: #{primaryblock.crc}"

    if primaryblock.crc == Integer.to_string(:crc32cer.nif(primarybinary), 16) do

      true

      else

      false

      end

  end

end
