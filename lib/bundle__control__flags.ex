defmodule Bundle_Control_Flags do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :bundle_is_fragment, boolean(), default: false
    field :administrative_record, boolean(), default: false
    field :bundle_must_not_be_fragmented, boolean(), default: false
    field :user_application_acknowledgement, boolean(), default: false
    field :status_time_reports, boolean(), default: false
    field :bundle_reception_recports, boolean(), default: false
    field :bundle_forwarding_reports, boolean(), default: false
    field :bundle_delivery_reports, boolean(), default: false
    field :bundle_deletion_reports, boolean(), default: false
  end


end
