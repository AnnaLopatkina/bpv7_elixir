defmodule Bpv7.Block_Control_Flags do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :replicate_block, boolean(), default: false
    field :status_report_transmission, boolean(), default: false
    field :delete_bundle, boolean(), default: false
    field :delete_block, boolean(), default: false
  end


end
