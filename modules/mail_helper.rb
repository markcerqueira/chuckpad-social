include SendGrid

module MailHelper

  # Helper method to send someone an email
  def self.send_email(to_field, subject_text, html_body_text)
    sendgrid_api_key = ENV['SENDGRID_API_KEY']
    if sendgrid_api_key.nil? or sendgrid_api_key.empty?
      LogHelper.mail_helper('send_email', 'SENDGRID_API_KEY not configured so cannot send email')
      return
    end

    begin
      from = Email.new(email: ENV['EMAIL_FROM_ADDRESS'].to_s, name: ENV['EMAIL_FROM_NAME'].to_s)
      to = Email.new(email: to_field)
      subject = subject_text
      content = Content.new(type: 'text/html', value: html_body_text)
      mail = Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)

      # Status Codes & Errors: https://sendgrid.com/docs/API_Reference/Web_API_v3/Mail/errors.html
      # 2xx responses indicate a successful request
      if response.status_code < 200 || response.status_code >= 300
        raise StandardError, "Error sending email: #{response.status_code.to_s}, #{response.body.to_s}, #{response.headers.to_s}"
      end
    rescue StandardError => e
      LogHelper.mail_helper('send_email', "exception thrown: #{e.message}")
    end
  end

end
