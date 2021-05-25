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

  def testbundle do
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
    #IO.puts "Primarybock to binary: #{:erlang.term_to_binary(primaryblock)}"
    CRC.crc_16(:erlang.term_to_binary(primaryblock))

  end
end
