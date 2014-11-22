class EmailProcessor
  
  def initialize(email)
    @email = email
  end

  def from_authorized?
    Bumper::Application.config.settings.
      authorized_emails.include?(@email.from[:email])
  end

  def bumper_addresses
    r = {supported: [], unsupported: []}
    @email.to.each do |to|
      next unless to[:host] == Bumper::Application.config.settings.from_host
      time = Chronic.parse(ChronicPreParse.parse(to[:token]))
      if time
        r[:supported].push([to[:token], time])
      else
        r[:unsupported].push(to[:token])
      end
    end
    r
  end

  def process
    return unless from_authorized?
    addrs = bumper_addresses
    addrs[:supported].each do |(token, time)|
      # Passing in the email token as a unique id
      # to prevent dupes when multiple reminders are in to field
      BumperWorker.perform_at(time, token, @email)
    end
    if addrs[:unsupported].any?
      HowToUseBumperWorker.
        perform_async(@email.from[:email], addrs[:unsupported])
    end
  end
end
