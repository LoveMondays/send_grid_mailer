module SendGridMailer
  class Definition
    METHODS = [
      :substitute,
      :set_template_id,
      :set_sender,
      :set_recipients,
      :set_subject,
      :set_content,
      :add_attachment,
      :add_header,
      :content?
    ]

    def substitute(key, value)
      personalization.substitutions = SendGrid::Substitution.new(key: key, value: value)
    end

    def set_template_id(value)
      return unless value
      mail.template_id = value
    end

    def set_sender(email)
      return unless email
      mail.from = SendGrid::Email.new(email: email)
    end

    def set_recipients(mode, *emails)
      emails.flatten.each do |email|
        next unless email
        personalization.send("#{mode}=", SendGrid::Email.new(email: email))
      end
    end

    def set_subject(value)
      return unless value
      personalization.subject = value
    end

    def set_content(value, type = nil)
      return unless value
      type = "text/plain" unless type
      mail.contents = SendGrid::Content.new(type: type, value: value)
    end

    def content?
      !mail.contents.blank?
    end

    def template_id?
      !mail.template_id.blank?
    end

    def add_attachment(file, name, type, disposition = "inline", content_id = nil)
      attachment = SendGrid::Attachment.new
      attachment.content = Base64.strict_encode64(file)
      attachment.type = type
      attachment.filename = name
      attachment.disposition = disposition
      attachment.content_id = content_id
      mail.attachments = attachment
    end

    def add_header(key, value)
      return if !key || !value
      personalization.headers = SendGrid::Header.new(key: key, value: value)
    end

    def to_json
      mail.personalizations = personalization if personalization?
      mail.to_json
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def log
      data = {
        "From" => mail.from,
        "To" => personalization.tos,
        "Cc" => personalization.ccs,
        "Bcc" => personalization.bccs,
        "Subject" => personalization.subject,
        "Template ID" => mail.template_id,
        "Substitutions" => personalization.substitutions,
        "Headers" => personalization.headers,
        "Contents" => mail.contents,
        "Attachments" => mail.attachments ? mail.attachments.map { |f| f["filename"] } : nil
      }

      data = data.keys.map do |k|
        d = data[k].to_s
        "#{k}: #{d.blank? ? '-' : d}"
      end.join("\n")

      Rails.logger.info(data)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def mail
      @mail ||= SendGrid::Mail.new
    end

    def personalization
      @personalization ||= SendGrid::Personalization.new
    end

    def personalization?
      !personalization.to_json.empty?
    end
  end
end
