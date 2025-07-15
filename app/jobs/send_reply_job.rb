class SendReplyJob < ApplicationJob
  queue_as :high

  retry_on Whatsapp::Providers::WhatsappBaileysService::MessageNotSentError, attempts: 3, wait: :polynomially_longer do |job, error|
    message_id = job.arguments.first
    message = Message.find_by(id: message_id)

    if message
      message.update!(status: :failed)
      Rails.logger.error "SendReplyJob failed after 3 attempts for message #{message_id}: #{error.message}"
    end
  end

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    channel_name = conversation.inbox.channel.class.to_s

    Rails.logger.info "SendReplyJob started for message #{message_id}, channel: #{channel_name}"

    services = {
      'Channel::TwitterProfile' => ::Twitter::SendOnTwitterService,
      'Channel::TwilioSms' => ::Twilio::SendOnTwilioService,
      'Channel::Line' => ::Line::SendOnLineService,
      'Channel::Telegram' => ::Telegram::SendOnTelegramService,
      'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService,
      'Channel::Sms' => ::Sms::SendOnSmsService,
      'Channel::Instagram' => ::Instagram::SendOnInstagramService
    }

    case channel_name
    when 'Channel::FacebookPage'
      send_on_facebook_page(message)
    else
      services[channel_name].new(message: message).perform if services[channel_name].present?
    end
  end

  private

  def send_on_facebook_page(message)
    if message.conversation.additional_attributes['type'] == 'instagram_direct_message'
      ::Instagram::Messenger::SendOnInstagramService.new(message: message).perform
    else
      ::Facebook::SendOnFacebookService.new(message: message).perform
    end
  end
end
