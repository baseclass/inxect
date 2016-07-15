Small library to make dependency injection with elixir easier, see documentation for more infos

## Build
[![Build Status](https://travis-ci.org/baseclass/inxect.svg?branch=master)](https://travis-ci.org/baseclass/inxect)

## Documentation
https://hexdocs.pm/inxect

## Hex

[![Hex.pm](https://img.shields.io/hexpm/dt/inxect.svg?maxAge=2592000)](https://hex.pm/packages/inxect)
[![Hex.pm](https://img.shields.io/hexpm/v/inxect.svg?maxAge=2592000)](https://hex.pm/packages/inxect)

## Example

```elixir
defmodule Localizer do
    @callback getHello :: String.t
end

defmodule Greeter do
    use Inxect.DI
    inject :localizer

    @spec sayHello(String.t) :: { :ok, String.t }
    defi sayHello(who, localizer) do
        { :ok, \#{localizer.getHello()} \#{who}}
    end
end

defmodule EnglishLocalizer do
    @behaviour Localizer
    
    @spec getHello :: String.t
    def getHello do
        hello
    end
end

defmodule Registry do
    use Inxect.Registry
    
    register { :localizer, EnglishLocalizer }
end
```

```elixir
iex(2)> Greeter.sayHello("Daniel")
{ :ok, "hello Daniel" }
```
