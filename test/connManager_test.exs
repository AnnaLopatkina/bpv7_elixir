defmodule Bpv7.ConnManager_test do
  use ExUnit.Case

  setup do
    Application.stop(:bpv7)
    :ok = Application.start(:bpv7)
  end

  test "add connection" do
    assert Bpv7.ConnManager.check_connection('localhost', 4040) == :not_found

    assert Bpv7.ConnManager.connect('localhost', 4040) == :ok
    assert Bpv7.ConnManager.check_connection('localhost', 4040) == :ok
  end


end