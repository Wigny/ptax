defmodule PTAX.Error do
  defexception ~w[message code details status]a

  @type t :: %PTAX.Error{message: binary, code: atom, details: map | binary, status: number}

  @spec new(Enum.t()) :: t
  def new(fields), do: struct!(__MODULE__, fields)
end
