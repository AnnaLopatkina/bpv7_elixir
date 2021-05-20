defmodule Creation_Time_Stamp do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :milliseconds, non_neg_integer()
    field :sequence, non_neg_integer()
  end
end
