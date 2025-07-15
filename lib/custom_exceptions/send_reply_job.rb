# frozen_string_literal: true

class CustomExceptions::SendReplyJob::MaxRetriesExceeded < CustomExceptions::Base
  def message
    I18n.t('errors.send_reply_job.max_retries_exceeded', message_id: @data[:message_id])
  end

  def http_status
    422
  end
end
