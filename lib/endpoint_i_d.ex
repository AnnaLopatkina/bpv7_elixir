defmodule EndpointID do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :scheme_name, String.t()
    field :scheme_number, non_neg_integer()
    field :authority, String.t()
    field :path, String.t()
    field :is_singleton, boolean()
  end

end
