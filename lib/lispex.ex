defmodule Lispex do
  def default_env(:inc), do: fn [x] -> x + 1 end
  def default_env(:dec), do: fn [x] -> x - 1 end
  def default_env(:+), do: fn [x, y] -> x + y end
  def default_env(:*), do: fn [x, y] -> x * y end
  def default_env(:=), do: fn [x, y] -> x == y end
  def default_env(:head), do: fn [[x | _]] -> x end
  def default_env(:tail), do: fn [[_ | xs]] -> xs end
  def default_env(:cons), do: fn [x, xs] -> [x | xs] end
  def default_env(:list), do: fn xs -> xs end
  def default_env(:nil?), do: fn [x] -> Enum.empty?(x) end

  def default_env(symbol) do
    raise "Error: Unbound symbol #{inspect(symbol)}"
  end

  def evaluate(expression, environment \\ &default_env/1)

  def evaluate(expression, _environment)
      when is_number(expression) or
             is_boolean(expression) or
             is_function(expression) or
             is_binary(expression) do
    expression
  end

  def evaluate(expression, environment)
      when is_atom(expression) do
    environment.(expression)
  end

  def evaluate([:lambda, params, body], environment) do
    make_lambda(params, body, environment)
  end

  def evaluate([:if, condition, consequent, alternative], environment) do
    if evaluate(condition, environment) do
      evaluate(consequent, environment)
    else
      evaluate(alternative, environment)
    end
  end

  def evaluate([:let, definitions, body], environment) do
    definitions
    |> Enum.reduce(environment, fn {symbol, definition}, environment ->
      fn env_symbol ->
        case env_symbol == symbol do
          true -> evaluate(definition, environment)
          false -> environment.(env_symbol)
        end
      end
    end)
    |> then(&evaluate(body, &1))
  end

  def evaluate(expression, environment) do
    invoke(expression, environment)
  end

  def invoke([operator | operands], environment \\ &default_env/1) do
    fun = evaluate(operator, environment)
    if not is_function(fun), do: raise("#{inspect(operator)} is not a function")
    args = Enum.map(operands, fn operand -> evaluate(operand, environment) end)
    fun.(args)
  end

  defp make_lambda(params, body, environment) do
    fn arguments ->
      new_environment = fn
        :rec ->
          make_lambda(params, body, environment)

        symbol ->
          case Enum.find_index(params, fn val -> val == symbol end) do
            nil -> environment.(symbol)
            index -> Enum.at(arguments, index)
          end
      end

      evaluate(body, new_environment)
    end
  end
end
