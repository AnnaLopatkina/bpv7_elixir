defmodule Bpv7.Canonical_Block do
  @moduledoc false
  # @type t() :: %__MODULE__{}
  use TypedStruct

  typedstruct do
    field :block_type_code, non_neg_integer()
    #primary block = 0, canonical block als payload block = 1, weitere canonical blocks = 2 bis n
    field :block_number, integer()
    field :block_control_flags, Block_Control_Flags.t()
    field :crc_type, non_neg_integer()
    field :block_type_specific_data, binary()
    field :crc, list(byte())
  end

end

