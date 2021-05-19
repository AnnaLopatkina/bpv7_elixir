defmodule Bundle do
  @moduledoc false
  use TypedStruct

  #bundle contains exactly one primary block and a list of canonical blocks (0 to multiple elements)
  typedstruct do
    field :primary_block, Primary_Block.t(), enforce: true
    field :canonical_block, list(Canonical_Block.t())
  end

end
