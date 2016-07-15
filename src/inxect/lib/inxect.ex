defmodule Inxect do
    
    defmodule DI do
        defprotocol Registry do
            def resolve(dependency)
        end
        defmacro __using__(_) do
            Module.register_attribute(__CALLER__.module, :injects, accumulate: true)
            quote do
                import Inxect.DI
            end
        end

        defmacro inject(inject) do
            Module.put_attribute(__CALLER__.module, :injects, inject)
        end

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
            IO.puts(Macro.to_string(publicFun))
            IO.puts(Macro.to_string(privateFun))
            IO.puts(Macro.to_string(testFun))
            quote do
                unquote(publicFun)
                unquote(privateFun)
                unquote(testFun)
            end
        end

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
                                ({:def, opt, [ { name, l, args } , impl ] }) ->
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
                                ({:spec, a, b }) ->
                                    IO.puts("-------------")
                                    IO.puts(Macro.to_string(b))
                                    IO.puts("-------------")
                                    {:spec, a, b }
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
end