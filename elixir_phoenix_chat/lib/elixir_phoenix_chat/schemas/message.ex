defmodule ElixirPhoenixChat.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, only: [:id, :user_id, :recipient_id, :content, :created_at, :sender_email, :recipient_email, :is_sent]}
  schema "messages" do
    field :user_id, :string
    field :recipient_id, :string
    field :content, :string
    field :created_at, :utc_datetime

    # Virtual fields for API responses
    field :sender_email, :string, virtual: true
    field :recipient_email, :string, virtual: true
    field :is_sent, :boolean, virtual: true

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:user_id, :recipient_id, :content, :created_at])
    |> validate_required([:user_id, :recipient_id, :content])
    |> validate_length(:content, min: 1, max: 5000)
    |> put_created_at()
  end

  defp put_created_at(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
    if Map.has_key?(changes, :created_at) do
      changeset
    else
      change(changeset, created_at: DateTime.utc_now())
    end
  end
end
