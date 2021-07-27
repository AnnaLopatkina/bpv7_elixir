defmodule Bpv7.Helpers do
    @moduledoc """
    Helper functions which may be used from different parts of Bpv7 Module.
    """

    def get_schedule_time(avail_begin) do
        current_time = DateTime.utc_now()
        schedule_time = DateTime.diff(avail_begin, current_time)
        schedule_time = cond do
          schedule_time < 0 ->
            0
          true ->
            schedule_time * 1000
        end
        schedule_time
    end

end