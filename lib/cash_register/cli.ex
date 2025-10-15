defmodule CashRegister.CLI do
  @moduledoc """
  Command-line interface for Cash Register.

  ## Usage

      cash_register INPUT_FILE OUTPUT_FILE [OPTIONS]

  ## Arguments

    * `INPUT_FILE` - Path to input file with comma-separated owed,paid amounts
    * `OUTPUT_FILE` - Path to output file for formatted change results

  ## Options

    * `--divisor N`, `-d N` - Custom divisor for strategy selection (default: 3)
    * `--currency CODE`, `-c CODE` - Currency code: USD, EUR (default: USD)
    * `--help`, `-h` - Show this help message
    * `--version`, `-v` - Show version information

  ## Examples

      cash_register input.txt output.txt
      cash_register input.txt output.txt --divisor 5
      cash_register input.txt output.txt --currency EUR
      cash_register input.txt output.txt -d 5 -c EUR
  """

  @doc """
  Main entry point for the escript.
  """
  @spec main([String.t()]) :: no_return()
  def main(args) do
    args
    |> parse_args()
    |> process()
    |> handle_result()
  end

  defp parse_args(args) do
    {opts, paths, invalid} =
      OptionParser.parse(args,
        strict: [divisor: :integer, currency: :string, help: :boolean, version: :boolean],
        aliases: [h: :help, v: :version, d: :divisor, c: :currency]
      )

    cond do
      opts[:help] ->
        :help

      opts[:version] ->
        :version

      length(invalid) > 0 ->
        {:error, "Invalid options: #{format_invalid_options(invalid)}"}

      length(paths) != 2 ->
        {:error, "Usage: cash_register INPUT_FILE OUTPUT_FILE [OPTIONS]"}

      true ->
        [input, output] = paths
        {:ok, input, output, opts}
    end
  end

  defp format_invalid_options(invalid) do
    Enum.map_join(invalid, ", ", fn {opt, _} -> opt end)
  end

  defp process(:help) do
    IO.puts(@moduledoc)
    System.halt(0)
  end

  defp process(:version) do
    {:ok, vsn} = :application.get_key(:cash_register, :vsn)
    IO.puts("Cash Register v#{vsn}")
    System.halt(0)
  end

  defp process({:ok, input, output, opts}) do
    CashRegister.process_file_and_output(input, output, opts)
  end

  defp process({:error, message}) when is_binary(message) do
    {:error, message}
  end

  @spec handle_result(:ok | {:error, term()}) :: no_return()
  defp handle_result(:ok) do
    IO.puts("Success: Change calculated and written to output file")
    System.halt(0)
  end

  defp handle_result({:error, error}) do
    message = format_error(error)
    IO.puts(:stderr, "Error: #{message}")
    System.halt(1)
  end

  defp format_error({:file_read_error, %{path: path, reason: :enoent}}) do
    "Cannot read file '#{path}': file not found"
  end

  defp format_error({:file_read_error, %{path: path, reason: :eacces}}) do
    "Cannot read file '#{path}': permission denied"
  end

  defp format_error({:file_read_error, %{path: path, reason: reason}}) do
    "Cannot read file '#{path}': #{:file.format_error(reason)}"
  end

  defp format_error({:file_write_error, %{path: path, reason: :eacces}}) do
    "Cannot write file '#{path}': permission denied"
  end

  defp format_error({:file_write_error, %{path: path, reason: :enospc}}) do
    "Cannot write file '#{path}': no space left on device"
  end

  defp format_error({:file_write_error, %{path: path, reason: reason}}) do
    "Cannot write file '#{path}': #{:file.format_error(reason)}"
  end

  defp format_error({:negative_amount, %{owed: owed, paid: paid}}) do
    "Invalid amounts: owed=#{owed}, paid=#{paid} (amounts must be non-negative)"
  end

  defp format_error({:insufficient_payment, %{owed: owed, paid: paid}}) do
    "Insufficient payment: owed=#{owed} cents, paid=#{paid} cents"
  end

  defp format_error({:invalid_line_format, %{line: line}}) do
    "Invalid line format: '#{line}'"
  end

  defp format_error({:invalid_amount_format, %{amount: amount, reason: reason}}) do
    "Invalid amount '#{amount}': #{reason}"
  end

  defp format_error({:invalid_divisor, %{divisor: divisor}}) do
    "Invalid divisor: #{inspect(divisor)} (must be a positive integer)"
  end

  defp format_error({:unknown_currency, %{currency: currency}}) do
    "Unknown currency: '#{currency}'"
  end

  defp format_error({:cannot_make_exact_change, %{remaining: remaining, change_cents: change}}) do
    "Cannot make exact change for #{change} cents (#{remaining} cents remaining with available denominations)"
  end

  defp format_error(error) when is_binary(error) do
    error
  end

  defp format_error(error) do
    "Unexpected error: #{inspect(error)}"
  end
end
