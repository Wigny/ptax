defmodule PTAX.Error do
  defexception ~w[message code]a

  @type t :: %PTAX.Error{message: binary, code: atom}

  @spec new(Enum.t()) :: t
  def new(fields), do: struct!(__MODULE__, fields)
end
