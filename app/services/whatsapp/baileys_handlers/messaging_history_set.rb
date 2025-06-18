module Whatsapp::BaileysHandlers::MessagingHistorySet
  include Whatsapp::BaileysHandlers::Helpers
  include BaileysHelper
  include Whatsapp::BaileysHandlers::MessagesUpsert

  private

  def process_messaging_history_set
    contacts = processed_params.dig(:data, :contacts) || []
    contacts.each do |contact|
      create_contact(contact) if jid_user(contact[:id])
    end
  end

  # TODO: Refactor jid_type method in helpers to receive the jid as an argument and use it here
  def jid_user(jid)
    server = jid.split('@').last
    server == 's.whatsapp.net' || server == 'c.us'
  end

  # TODO: Refactor this method in helpers to receive the jid as an argument and remove it from here
  def phone_number_from_jid(jid)
    jid.split('@').first.split(':').first.split('_').first
  end

  def create_contact(contact)
    phone_number_from_jid = phone_number_from_jid(contact[:id])
    name = contact[:verifiedName].presence || contact[:name].presence || phone_number_from_jid
    ::ContactInboxWithContactBuilder.new(
      # FIXME: update the source_id to complete jid in future
      source_id: phone_number_from_jid,
      inbox: inbox,
      contact_attributes: { name: name, phone_number: "+#{phone_number_from_jid}" }
    ).perform
  end
end