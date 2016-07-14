defmodule InxectTest do
  use ExUnit.Case
  doctest Inxect

  defmodule LocalizerStub do
    @behaviour Localizer

    def getHello do
      "test"
    end
  end

  test "with injection" do
    assert Greeter.sayHello("daniel") == {:ok, "hello daniel" }
  end

  test "with stub" do
    assert Greeter.test_sayHello("daniel", LocalizerStub) == {:ok, "test daniel" }
  end
end

defmodule Greeter do
  use Inxect.DI
  
  inject {:localizer, Localizer} do
    #@spec sayHello(String.t,atom) :: { :ok, String.t }
    def sayHello(who, localizer) do
      { :ok, "#{localizer.getHello()} #{who}"}
    end
  end
end

defmodule Localizer do
  @callback getHello :: String.t
end

defmodule EnglishLocalizer do
  @behaviour Localizer
  
  @spec getHello :: String.t
  def getHello do
    "hello"
  end
end