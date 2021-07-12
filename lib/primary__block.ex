defmodule Bpv7.Primary_Block do
  @moduledoc false
  # @type t() :: %__MODULE__{}
  use TypedStruct

  typedstruct do
    field :version, non_neg_integer()
    #field :bundle_control_flags, Bundle_Control_Flags.t()
    field :bundle_control_flags, non_neg_integer()
    field :crc_type, non_neg_integer()
    #field :destination, EndpointID.t()
    #field :source_node, EndpointID.t()
    #field :report_to, EndpointID.t()
    field :destination, list()
    field :source_node, list()
    field :report_to, list()
    field :creation_time_stamp, list()
    field :lifetime, non_neg_integer()
    field :fragment_offset, integer()
    field :crc, String.t()
  end

end
