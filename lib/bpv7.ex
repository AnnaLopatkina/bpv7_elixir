defmodule Bpv7 do
  use Timex
  @moduledoc """
  Documentation for `Bpv7`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Bpv7.hello()
      :world

  """
  def hello do
    :world
  end

  def testprimaryblock do
    # Test primary block
    bundle_control_flags = %Bundle_Control_Flags{bundle_must_not_be_fragmented: true}
    endpointid = %EndpointID{scheme_name: "dtn", scheme_number: 1, authority: "u3dtn-node", path: "node1", is_singleton: true}
    endpointidsource = %EndpointID{scheme_name: "dtn", scheme_number: 1, authority: "u3dtn-node", path: "node2", is_singleton: true}

    bpv7_epoch = "2000-01-01 00:00:00"
    bpv7_epoch_date = Timex.parse!(bpv7_epoch, "%Y-%m-%d %H:%M:%S", :strftime)
    bpv7_epoch_milliseconds = DateTime.to_unix(Timex.to_datetime(bpv7_epoch_date), :millisecond)
    now_milliseconds = DateTime.to_unix(Timex.now(), :millisecond)
    creationtimestamp = %Creation_Time_Stamp{milliseconds: now_milliseconds-bpv7_epoch_milliseconds, sequence: 1}
    IO.puts "BPv7 Epoch: #{bpv7_epoch_milliseconds} Milliseconds now: #{now_milliseconds}"
    IO.puts "Result: #{now_milliseconds - bpv7_epoch_milliseconds}"

    primaryblock = %Primary_Block{version: 7, bundle_control_flags: bundle_control_flags, crc_type: 1, \
    destination: endpointid, source_node: endpointidsource, report_to: endpointid, creation_time_stamp: creationtimestamp, \
    lifetime: 360000, crc: [0000,0000,0000,0000]}
    primaryblock
  end
  def crcprimaryblock(testprimaryblock()) do
    #IO.puts "Primarybock to binary: #{:erlang.term_to_binary(primaryblock)}"
    CRC.crc_16(:erlang.term_to_binary(primaryblock))
  end
  def canonical_testblock do    # Test canonical block
    block_control_flags_eins = %Block_Control_Flags{replicate_block: true, status_report_transmission: true, delete_bundle: true, delete_block: true}
    block_control_flags_zwei = %Block_Control_Flags{replicate_block: true, status_report_transmission: true, delete_bundle: true, delete_block: true}
    endpointID = %EndpointID{scheme_name: "dtn", scheme_number: 1, authority: "u3dtn-node", path: "node1", is_singleton: true}

    canonicalblockEins = %Cononical_Block{block_number: 1 , block_type_code: 1,\
      block_control_flags: block_control_flag_eins, crc_type: 1 , crc: [0000,0000,0000,0000],\
      block_type_specific_data: :erlang.term_to_binary("hallo") }
    canonicalblockZwei = %Cononical_Block{block_number: 2 , block_type_code: 6,\
      block_control_flags: block_control_flag_zwei, crc_type: 1 , crc: [0000,0000,0000,0000], \
      block_type_specific_data: :erlang.term_to_binary(endpointID) }

    [canonicalblockEins, canonicalblockZwei]

  end

  def crcprimaryblock(primaryblock) do
    CRC.crc_16(:erlang.term_to_binary(primaryblock))
  end
end

