defmodule Inxect do
    defmodule DI do
        defmacro __using__(_) do
            quote do
                import Inxect.DI
            end
        end

        defmacro inject(_opts, do: block) do
            publicFun = create_without_dependencies(block)
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

        def resolve(:localizer) do
            EnglishLocalizer
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

        defp create_without_dependencies(block) do
            Macro.prewalk(block,fn 
                                ({:def, opt, [ { name, l, args } , impl ] }) ->
                                    IO.puts("-------------")
                                    nargs = remove_dependencies(args)
                                    pass = replace_dependencies(args)
                                    impl = [do: {name, [], pass}]
                                    IO.inspect(impl)
                                    IO.puts("-------------")
                                    {:def, opt, [ { name, l, nargs }, impl ] }
                                ({:spec, a, b }) ->
                                    IO.puts("-------------")
                                    IO.puts(Macro.to_string(b))
                                    IO.puts("-------------")
                                    {:spec, a, b }
                                node -> node
                            end)
        end

        defp replace_dependencies([ {:localizer, _, _ } | t]) do
            [ {:resolve, [], [:localizer]} ] ++ replace_dependencies(t)
        end
        defp replace_dependencies([h | t]) do
            [ h ] ++ replace_dependencies(t)
        end
        defp replace_dependencies([]) do
            []
        end

        defp remove_dependencies([ {:localizer, _, _ } | t]) do
            remove_dependencies(t)
        end
        defp remove_dependencies([h | t]) do
            [ h ] ++ remove_dependencies(t)
        end
        defp remove_dependencies([]) do
            []
        end
    end
end