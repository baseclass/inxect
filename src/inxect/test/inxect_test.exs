defmodule InxectTest do
  use ExUnit.Case
  doctest Inxect

  test "the truth" do
    assert Greeter.sayHello("daniel") == {:ok, "hello daniel" }
  end
end

defmodule Greeter do
  @spec sayHello(String.t) :: { :ok, String.t }
  def sayHello(who) do
    sayHello(who, EnglishLocalizer)
  end
  
  @spec sayHello(String.t,atom) :: { :ok, String.t }
  defp sayHello(who, module) do
    { :ok, "#{module.getHello()} #{who}"}
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