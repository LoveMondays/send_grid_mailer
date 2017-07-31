module SendGridMailer
  class Deliverer
    include InterceptorsHandler
    include Logger

    def deliver!(sg_definition)
      execute_interceptors(sg_definition)
      log_definition(sg_definition)
      sg_api.send_mail(sg_definition)
    end

    private

    def sg_api
      @sg_api ||= Api.new(api_keys[current_key])
    end

    def api_keys
      {
        br: ENV.fetch('SENDGRID_API_KEY_BR'),
        mx: ENV.fetch('SENDGRID_API_KEY_MX'),
        ar: ENV.fetch('SENDGRID_API_KEY_AR')
      }
    rescue
      nil
    end

    def current_key
      Countries.current.iso_2_code.downcase.to_sym
    end
  end
end
