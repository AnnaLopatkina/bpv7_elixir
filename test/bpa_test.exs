defmodule Bpv7.BPA_test do
  use ExUnit.Case

  test "add and save node" do
    assert Bpv7.BPA.get_tcp_conn_details("dtn://test.dtn") == :not_found

    {:ok, begin_time, 0} = DateTime.from_iso8601("2021-07-17T13:05:00Z")
    {:ok, end_time, 0} = DateTime.from_iso8601("2021-07-19T23:48:00Z")
    Bpv7.BPA.add_tcp_node("dtn://test.dtn",'localhost', 4040, begin_time, end_time)

    assert Bpv7.BPA.get_connection_method("dtn://test.dtn") == :tcp
    assert Bpv7.BPA.get_tcp_conn_details("dtn://test.dtn") == {'localhost', 4040}
    assert Bpv7.BPA.get_availability("dtn://test.dtn") == {begin_time, end_time}

  end
end