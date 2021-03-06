defmodule GenserverTest do
  use ExUnit.Case

  defmodule MyServer do
    use OtpDsl.Genserver, register: {:local, :myname}

    defcall an_api() do
      reply({1,2})
    end

    defcall api_with_params_and_state(num), state do
      reply(state + num)
    end

    defcall api_with_params_sets_state(num), state do
      reply(state + num, state - num)
    end

    defcast a_broadcast(), state do
      noreply(state)
    end
  end

  defmodule SecondServer do
    use OtpDsl.Genserver
    def init(state) do
      { :ok, state + 321 }
    end
  end

  defmodule FactorialServer do
    use OtpDsl.Genserver

    defcall factorial!(n) do
      reply(Enum.reduce(1..n, 1, &(&1*&2)))
    end
  end

  defmodule KvServer do
    use OtpDsl.Genserver, initial_state: HashDict.new

    defcall put(key, value), kv_store do
      reply(value, Dict.put(kv_store, key, value))
    end

    defcall get(key), kv_store do
      reply(Dict.get(kv_store, key))
    end
  end

  defmodule BroadcastServer do
    use OtpDsl.Genserver

    defcast say_hello(from, name) do
      from <- {:hello, name}
      noreply
    end
  end

  test "the server name gets set" do
    assert MyServer.my_name == :myname
  end

  test "a default server name, based on the module name, is used if none is set" do
    assert SecondServer.my_name == :genserver_test_second_server
  end

  test "the default init function returns unmodified state" do
    assert MyServer.init(123) == { :ok, 123 }
  end

  test "an overridden init function returns new state" do
    assert SecondServer.init(123) == { :ok, 444 }
  end

  test "a simple handle function is established" do
    assert MyServer.handle_call({:an_api}, :from, :state) == { :reply, {1,2}, :state }
  end

  test "a handle function with params that uses state" do
    assert MyServer.handle_call({:api_with_params_and_state, 123}, :from, 321) == { :reply, 444, 321 }
  end

  test "a handle function with params that sets state" do
    assert MyServer.handle_call({:api_with_params_sets_state, 123}, :from, 321) == { :reply, 444, 198 }
  end

  test "a handle function exists for cast message" do
    assert MyServer.handle_cast({:a_broadcast}, :state) == {:noreply, :state}
  end

  test "The factorial server works" do
    FactorialServer.start_link
    assert FactorialServer.factorial!(10) == 3628800
  end

  test "The KV server works" do
    KvServer.start_link
    assert KvServer.get(:one)    == nil
    assert KvServer.put(:one, 1) == 1
    assert KvServer.put(:two, 2) == 2
    assert KvServer.get(:two)    == 2
    assert KvServer.get(:one)    == 1
  end

  test "The broadcast server works" do
    BroadcastServer.start_link
    BroadcastServer.say_hello(self, "Elixir")
    assert_receive {:hello, "Elixir"}, 100
  end
end
