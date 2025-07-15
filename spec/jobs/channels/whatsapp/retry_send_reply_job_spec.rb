require 'rails_helper'

RSpec.describe Channels::Whatsapp::RetrySendReplyJob do
  it 'enqueues the job' do
    expect { described_class.perform_later(1) }.to have_enqueued_job(described_class)
      .with(1)
      .on_queue('high')
  end

  context 'when called' do
    let!(:whatsapp_channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
    end
    let!(:whatsapp_channel_not_baileys) do
      create(:channel_whatsapp, provider: 'default', validate_provider_config: false, sync_templates: false)
    end
    let!(:inbox) { create(:inbox, channel: whatsapp_channel) }
    let!(:conversation) { create(:conversation, inbox: inbox) }

    it 'does not perform for channels other than baileys' do
      described_class.perform_now(whatsapp_channel_not_baileys.id)
      expect(SendReplyJob).not_to have_been_enqueued
    end

    it 'does not perform if there are no messages' do
      message = build(:message, conversation: conversation, message_type: :outgoing, status: :read)
      allow(message).to receive(:send_reply)
      message.save!
      described_class.perform_now(whatsapp_channel.id)
      expect(SendReplyJob).not_to have_been_enqueued
    end

    it 'enqueues SendReplyJob for messages' do
      failed_message = build(:message, conversation: conversation, message_type: :outgoing, status: :sent)
      allow(failed_message).to receive(:send_reply)
      failed_message.save!
      # This one should not be picked up
      old_message = build(:message, conversation: conversation, message_type: :outgoing, status: :sent, created_at: 2.days.ago)
      allow(old_message).to receive(:send_reply)
      old_message.save!
      # This one should not be picked up
      delivered_message = build(:message, conversation: conversation, message_type: :outgoing, status: :delivered)
      allow(delivered_message).to receive(:send_reply)
      delivered_message.save!

      described_class.perform_now(whatsapp_channel.id)

      expect(SendReplyJob).to have_been_enqueued.with(failed_message.id)
    end

    it 'handles errors during SendReplyJob enqueue and marks message as failed' do
      failed_message = build(:message, conversation: conversation, message_type: :outgoing, status: :sent)
      allow(failed_message).to receive(:send_reply)
      failed_message.save!
      allow(SendReplyJob).to receive(:perform_later).and_raise(StandardError)

      described_class.perform_now(whatsapp_channel.id)

      expect(failed_message.reload.status).to eq('failed')
    end
  end
end
