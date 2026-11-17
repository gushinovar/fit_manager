defmodule FitManager.Messaging.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field :phone, :string
    field :channel, :string, default: "whatsapp"
    field :direction, :string
    field :message, :string
    field :message_body, :string
    field :status, :string, default: "received"
    field :message_at, :utc_datetime
    field :meta_message_id, :string
    field :metadata, :map, default: %{}
    field :raw_payload, :map, default: %{}

    belongs_to :client, FitManager.Clients.Client

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :client_id,
      :phone,
      :channel,
      :direction,
      :message,
      :message_body,
      :status,
      :message_at,
      :meta_message_id,
      :metadata,
      :raw_payload
    ])
    |> normalize_fields()
    |> validate_required([:direction])
    |> validate_message_present()
    |> validate_inclusion(:direction, ["inbound", "outbound"])
    |> validate_inclusion(:channel, ["whatsapp", "manual"])
    |> foreign_key_constraint(:client_id)
  end

  defp normalize_fields(changeset) do
    message = get_change(changeset, :message) || get_field(changeset, :message)
    message_body = get_change(changeset, :message_body) || get_field(changeset, :message_body)

    changeset =
      cond do
        message && is_nil(message_body) ->
          put_change(changeset, :message_body, message)

        message_body && is_nil(message) ->
          put_change(changeset, :message, message_body)

        true ->
          changeset
      end

    message_at = get_change(changeset, :message_at) || get_field(changeset, :message_at)

    if is_nil(message_at) do
      put_change(changeset, :message_at, DateTime.utc_now() |> DateTime.truncate(:second))
    else
      changeset
    end
  end

  defp validate_message_present(changeset) do
    message = get_change(changeset, :message) || get_field(changeset, :message)
    message_body = get_change(changeset, :message_body) || get_field(changeset, :message_body)

    if (is_nil(message) or message == "") and (is_nil(message_body) or message_body == "") do
      add_error(changeset, :message, "can't be blank")
    else
      changeset
    end
  end
end
