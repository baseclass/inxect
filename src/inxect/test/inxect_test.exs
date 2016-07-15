defmodule Localizer do
  @callback getHello :: String.t
end

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

  test "without injection fails" do
     assert_raise UndefinedFunctionError, fn -> 
      Greeter.sayHello("daniel", LocalizerStub)
     end
  end

  test "public functions" do
    assert Greeter.__info__(:functions) == [sayHello: 1, test_sayHello: 2]
  end
end

defmodule Registry do
  defimpl Inxect.DI.Registry, for: Atom do
    def resolve(:localizer) do
      EnglishLocalizer
    end
  end
end

defmodule Greeter do
  use Inxect.DI
  inject :localizer

  @spec sayHello(String.t) :: { :ok, String.t }
  defi sayHello(who, localizer) do
    { :ok, "#{localizer.getHello()} #{who}"}
  end
end

defmodule EnglishLocalizer do
  @behaviour Localizer
  
  @spec getHello :: String.t
  def getHello do
    "hello"
  end
end