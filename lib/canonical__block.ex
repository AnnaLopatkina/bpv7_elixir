defmodule Canonical_Block do
  @moduledoc false
  # @type t() :: %__MODULE__{}
  use TypedStruct

  typedstruct do
    field :block_number, integer()
    field :block_control_flags, Block_Control_Flags.t()
    field :crc_type, CRC_Type.t()
    field :crc, list(byte())
    field :value, Extension_Block.t()
  end

end
