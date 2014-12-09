defmodule OtpDsl.Mixfile do
  use Mix.Project

  def project do
    [
      app:     :otp_dsl,
      version: "0.1.0",
      elixir:  ">= 1.0.0 ",
      deps:    deps(Mix.env)
    ]
  end

  defp deps(:prod), do: [ ]
  defp deps(_),     do: [ {:meck,  github: "eproxus/meck" } ]

end
