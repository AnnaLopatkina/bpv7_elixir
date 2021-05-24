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
    creationtimestamp = %Creation_Time_Stamp{milliseconds: 5, sequence: 1}

    primaryblock = %Primary_Block{version: 7, bundle_control_flags: bundle_control_flags, crc_type: 1, \
    destination: endpointid, source_node: endpointidsource, report_to: endpointid, creation_time_stamp: creationtimestamp, \
    lifetime: 360000, crc: [0000,0000,0000,0000]}
    primaryblock

  end
end
