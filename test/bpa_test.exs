defmodule Bpv7.BPA_test do
  use ExUnit.Case

  test "add and save node" do
    assert Bpv7.BPA.get_tcp_conn_details("dtn://test.dtn") == :not_found

    current_time = DateTime.utc_now()
    end_time = DateTime.add(current_time, 3600, :second)
    Bpv7.BPA.add_tcp_node("dtn://test.dtn",'localhost', 4040, current_time, end_time)

    assert Bpv7.BPA.get_connection_method("dtn://test.dtn") == :tcp
    assert Bpv7.BPA.get_tcp_conn_details("dtn://test.dtn") == {'localhost', 4040}
    assert Bpv7.BPA.get_availability("dtn://test.dtn") == {current_time, end_time}

  end

  test "remvove outdated entries" do
    assert Bpv7.BPA.get_tcp_conn_details("dtn://test-remove.dtn") == :not_found
    
    current_time = DateTime.utc_now()
    end_time = DateTime.add(current_time, -5, :second)
    current_time |> DateTime.add(-10, :second)
    Bpv7.BPA.add_tcp_node("dtn://test-remove.dtn",'localhost', 4040, current_time, end_time)

    assert Bpv7.BPA.get_tcp_conn_details("dtn://test-remove.dtn") == :not_found
  end
end