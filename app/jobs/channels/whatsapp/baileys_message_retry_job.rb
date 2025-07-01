class Channels::Whatsapp::BaileysMessageRetryJob < ApplicationJob
  include BaileysHelper

  queue_as :high

  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(message_id, attempt_count = 1)
    message = Message.find(message_id)
    return unless message.conversation.inbox.channel.provider == 'baileys'

    with_baileys_channel_lock_on_outgoing_message(message.conversation.inbox.channel.id) do
      send_baileys_message(message, attempt_count)
    end
  rescue Whatsapp::Providers::WhatsappBaileysService::MessageNotSentError => e
    handle_baileys_send_failure(message, attempt_count, e)
  rescue StandardError => e
    Rails.logger.error "Unexpected error in BaileysMessageRetryJob: #{e.message}"
    handle_baileys_send_failure(message, attempt_count, e)
  end

  private

  def send_baileys_message(message, attempt_count)
    service = Whatsapp::SendOnWhatsappService.new(message: message)
    service.perform

    message.update!(status: :sent, additional_attributes: message.additional_attributes.merge(
      baileys_retry_count: attempt_count,
      baileys_last_attempt_at: Time.current
    ))

    Rails.logger.info "Baileys message sent successfully on attempt #{attempt_count} for message #{message.id}"
  end

  def handle_baileys_send_failure(message, attempt_count, error)
    Rails.logger.warn "Baileys message send failed on attempt #{attempt_count} for message #{message.id}: #{error.message}"

    message.update!(
      status: :failed,
      additional_attributes: message.additional_attributes.merge(
        baileys_retry_count: attempt_count,
        baileys_last_attempt_at: Time.current,
        baileys_last_error: error.message
      )
    )

    if attempt_count >= 3
      persist_failed_message_for_redelivery(message)
    else
      retry_delay = calculate_retry_delay(attempt_count)
      self.class.set(wait: retry_delay).perform_later(message.id, attempt_count + 1)
    end
  end

  def calculate_retry_delay(attempt_count)
    base_delay = 30.seconds
    [base_delay * (2 ** (attempt_count - 1)), 5.minutes].min
  end

  def persist_failed_message_for_redelivery(message)
    failed_message_key = "baileys:failed_messages:#{message.conversation.inbox.channel.id}"
    message_data = {
      message_id: message.id,
      failed_at: Time.current.to_i,
      retry_count: message.additional_attributes['baileys_retry_count'] || 0,
      last_error: message.additional_attributes['baileys_last_error']
    }

    Redis::Alfred.lpush(failed_message_key, message_data.to_json)
    Rails.logger.info "Persisted failed Baileys message #{message.id} for future redelivery"
  end
end
