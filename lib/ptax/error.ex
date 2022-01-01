defmodule PTAX.Error do
  defexception ~w[message code extra]a

  @type t :: %PTAX.Error{message: binary, code: atom, extra: map | nil}

  @spec new(Enum.t()) :: t
  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
