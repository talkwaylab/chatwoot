class Channels::Whatsapp::RetrySendReplyJob < ApplicationJob
  queue_as :high

  def perform(channel_id)
    channel = Channel::Whatsapp.find(channel_id)
    return unless channel.provider == 'baileys'

    failed_messages = find_failed_messages(channel)
    return if failed_messages.empty?

    Rails.logger.info "Processing #{failed_messages.count} failed messages for Baileys channel #{channel_id}"

    failed_messages.each do |message|
      process_message(message)

      sleep(10) unless message == failed_messages.last
    end
  end

  private

  def find_failed_messages(channel)
    Message.joins(:conversation)
           .joins('JOIN inboxes ON conversations.inbox_id = inboxes.id')
           .where(inboxes: { channel: channel })
           .where(status: :sent)
           .where('messages.created_at > ?', 24.hours.ago)
           .where(message_type: :outgoing)
           .order(:created_at)
  end

  def process_message(message)
    SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    Rails.logger.error "Error processing failed message #{message.id}: #{e.message}"
    message.update!(status: :failed)
  end
end
