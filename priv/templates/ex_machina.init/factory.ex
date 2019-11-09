defmodule <%= module %>.Factory do

<%= if ecto == false do %>  use ExMachina<% else %>  use ExMachina.Ecto, repo: <%= module %>.Repo<% end %>

end
