defmodule ElixirPhoenixChat.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @derive {Jason.Encoder, only: [:id, :email, :created_at]}
  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :created_at, :utc_datetime

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :email, :password, :created_at])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
    |> put_password_hash()
    |> put_created_at()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp put_created_at(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
    if Map.has_key?(changes, :created_at) do
      changeset
    else
      change(changeset, created_at: DateTime.utc_now())
    end
  end
end
