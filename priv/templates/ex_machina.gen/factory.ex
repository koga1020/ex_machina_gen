defmodule <%= module %> do
  defmacro __using__(_opts) do
    quote do
      def <%= singular %>_factory do
        <%= struct_string %>
      end
    end
  end
end
