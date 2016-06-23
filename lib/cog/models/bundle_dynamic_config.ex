defmodule Cog.Models.BundleDynamicConfig do
  use Cog.Model, :no_primary_key

  alias Cog.Models.Bundle

  schema "bundle_dynamic_configs" do
    field :config, :map
    field :hash, :string

    belongs_to :bundle, Bundle, [foreign_key: :bundle_id]

    timestamps

  end

  @required_fields ~w(bundle_id config)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:bundle_id, name: :bundle_dynamic_configs_bundle_id_index)
    |> calculate_hash
  end

  defp calculate_hash(changeset) do
    case fetch_change(changeset, :config) do
      :error ->
        changeset
      {:ok, config} ->
        json = Poison.encode!(config)
        hash = :crypto.hash(:sha256, json) |> Base.encode16 |> String.downcase
        put_change(changeset, :hash, hash)
    end
  end

end
