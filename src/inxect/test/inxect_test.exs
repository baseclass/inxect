defmodule Localizer do
  @callback getHello :: String.t
  @callback getGoodbye :: String.t
end

defmodule InxectTest do
  use ExUnit.Case
  doctest Inxect

  defmodule LocalizerStub do
    @behaviour Localizer

    def getHello do
      "test"
    end
    def getGoodbye do
      "tset"
    end
  end

  test "sayHello with injection" do
    assert Greeter.sayHello("daniel") == {:ok, "hello daniel" }
  end

  test "sayGoodbye with injection" do
    assert Greeter.sayGoodbye("daniel") == {:ok, "good bye daniel" }
    assert Greeter.sayGoodbye() == {:ok, "good bye " }
  end

  test "sayHello with stub" do
    assert Greeter.test_sayHello("daniel", LocalizerStub) == {:ok, "test daniel" }
  end

  test "sayGoodbye with stub" do
    assert Greeter.test_sayGoodbye("daniel", LocalizerStub) == {:ok, "tset daniel" }
    assert Greeter.test_sayGoodbye(LocalizerStub) == {:ok, "tset " }
  end

  test "sayHello without injection fails" do
     assert_raise UndefinedFunctionError, fn -> 
      Greeter.sayHello("daniel", LocalizerStub)
     end
  end

  test "sayGoodbye without injection fails" do
     assert_raise UndefinedFunctionError, fn -> 
      Greeter.sayGoodbye("daniel", LocalizerStub)
     end
  end

  test "public functions" do
    assert Greeter.__info__(:functions) == [sayGoodbye: 0, sayGoodbye: 1, sayHello: 1, test_sayGoodbye: 1, test_sayGoodbye: 2, test_sayHello: 2]
  end
end

defmodule Registry do
  use Inxect.Registry
  
  register { :localizer, EnglishLocalizer }
end

defmodule Greeter do
  use Inxect.DI
  inject :localizer

  @spec sayHello(String.t) :: { :ok, String.t }
  defi sayHello(who, localizer) do
    { :ok, "#{localizer.getHello()} #{who}"}
  end

  @spec sayGoodbye(String.t) :: { :ok, String.t }
  defi sayGoodbye(who \\ "", localizer) do
    { :ok, "#{localizer.getGoodbye()} #{who}"}
  end
end

defmodule EnglishLocalizer do
  @behaviour Localizer
  
  @spec getHello :: String.t
  def getHello do
    "hello"
  end
  
  @spec getGoodbye :: String.t
  def getGoodbye do
    "good bye"
  end
end