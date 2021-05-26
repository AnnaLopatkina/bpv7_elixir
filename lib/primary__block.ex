defmodule Primary_Block do
  @moduledoc false
  # @type t() :: %__MODULE__{}
  use TypedStruct

  typedstruct do
    field :version, non_neg_integer()
    field :bundle_control_flags, Bundle_Control_Flags.t()
    field :crc_type, non_neg_integer()
    field :destination, EndpointID.t()
    field :source_node, EndpointID.t()
    field :report_to, EndpointID.t()
    field :creation_time_stamp, Creation_Time_Stamp.t()
    field :lifetime, non_neg_integer()
    field :fragment_offset, integer()
    field :total_data_length, integer()
    field :crc, list(byte())
  end

end
