defmodule Inxect do
    @moduledoc ~S"""
    Macros for making dependency injection easier

    ## Example

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

        iex(2)> Greeter.sayHello("Daniel")
        { :ok, "hello Daniel" }

    """

    defmodule DI do
        @moduledoc """
        Macros which replace function arguments with implementations using dependency injection.
        Use this module to inject dependencies and Inxect.Registry to create a registry.
        """ 

        @doc false
        defprotocol Registry do
            def resolve(dependency)
        end
        
        @doc false
        defmacro __using__(_) do
            Module.register_attribute(__CALLER__.module, :injects, accumulate: true)
            quote do
                import Inxect.DI
            end
        end

        @doc """
        Specify a function parameter which should be injected 
        """
        @spec inject(atom) :: nil
        defmacro inject(inject) do
            Module.put_attribute(__CALLER__.module, :injects, inject)
            nil
        end

        @doc ~S"""
        Specify a function where injection should be applied, all the argument names
        which have been marked for injection with inject/1 will be replaced.

        ## Example

            defi sayHello(who, localizer) do
                { :ok, "\#{localizer.getHello()} \#{who}"}
            end

        will be compiled like that:

            def sayHello(who) do
                sayHello(who, resolve(:localizer))
            end
            defp sayHello(who, localizer) do
                {:ok, "\#{localizer.getHello()} \#{who}"}
            end

            def(test_sayHello(who, localizer)) do
                sayHello(who, localizer)
            end
        """
        defmacro defi(head, body) do
            injects = Module.get_attribute(__CALLER__.module, :injects)
            block = quote do
                        def unquote(head) do
                            unquote(body[:do])
                        end
                    end
            
            publicFun = create_without_dependencies(injects, block)
            privateFun = make_private(block)
            testFun = create_test_fun(block)
            quote do
                unquote(publicFun)
                unquote(privateFun)
                unquote(testFun)
            end
        end

        @doc false
        def resolve(dependency) do
            Registry.resolve(dependency)
        end

        defp make_private(block) do
            Macro.prewalk(block,fn 
                                ({:def, opt, impl }) ->
                                    {:defp, opt, impl }
                                node -> node
                            end)
        end

        defp create_test_fun(block) do
            Macro.prewalk(block,fn 
                                ({:def, opt, [ { name, l, args } , _impl ] }) ->
                                    impl = [do: {name, [], args}]
                                    {:def, opt, [ { String.to_atom("test_#{name}"), l, args }, impl ] }
                                node -> node
                            end)
        end

        defp create_without_dependencies(injects, block) do
            Macro.prewalk(block,fn 
                                ({:def, opt, [ { name, l, args } , _impl ] }) ->
                                    nargs = remove_all_dependencies(injects, args)
                                    pass = replace_all_dependencies(injects, args)
                                    impl = [do: {name, [], pass}]
                                    {:def, opt, [ { name, l, nargs }, impl ] }
                                node -> node
                            end)
        end

        defp replace_all_dependencies([ h | t ], args) do
            args = replace_dependencies(h, args)
            replace_all_dependencies(t, args)
        end
        defp replace_all_dependencies([], args) do
            args
        end

        defp replace_dependencies(dep, [ {dep, _, _ } | t]) do
            [ {:resolve, [], [dep]} ] ++ replace_dependencies(dep, t)
        end
        defp replace_dependencies(dep, [h | t]) do
            [ h ] ++ replace_dependencies(dep, t)
        end
        defp replace_dependencies(_dep, []) do
            []
        end

        defp remove_all_dependencies([ h | t ], args) do
            args = remove_dependencies(h, args)
            remove_all_dependencies(t, args)
        end
        defp remove_all_dependencies([], args) do
            args
        end

        defp remove_dependencies(dep, [ {dep, _, _ } | t]) do
            remove_dependencies(dep, t)
        end
        defp remove_dependencies(dep, [h | t]) do
            [ h ] ++ remove_dependencies(dep, t)
        end
        defp remove_dependencies(_dep, []) do
            []
        end
    end

    defmodule Registry do
        @moduledoc """
        DSL to implement a registry.

        ## Example

            defmodule Registry do
                use Inxect.Registry
                
                register { :localizer, EnglishLocalizer }
            end
        """ 

        @doc false
        defmacro __using__(_) do
            Module.register_attribute(__CALLER__.module, :registrations, accumulate: true)
            quote do
                import Inxect.Registry
                
                @before_compile Inxect.Registry
            end
        end

        @doc """
        Register a dependencency

        ## Example
            register { :localizer, EnglishLocalizer }
        """
        @spec register(reg :: { atom, atom }) :: any
        defmacro register(reg) do
            Module.put_attribute(__CALLER__.module, :registrations, reg)
            quote do
            end
        end

        @doc false
        defmacro __before_compile__(env) do
            regs = Module.get_attribute(env.module, :registrations)
            
            compiled_regs = compile_dependencies(regs)
            
            protoclImpl = quote do
                                defimpl Inxect.DI.Registry, for: Atom do
                                    unquote_splicing(compiled_regs)
                                end
                            end
            
            protoclImpl
        end
        defp compile_dependencies([ { key, dependency } | t]) do
            reg = quote do
                    def resolve(unquote(key)) do
                        unquote(dependency)
                    end
                  end
            [reg] ++ compile_dependencies(t)
        end
        defp compile_dependencies([]) do
            []
        end
    end
end