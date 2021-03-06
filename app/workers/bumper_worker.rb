class BumperWorker
  include Sidekiq::Worker

  # If there are multiple reminders scheduled at once, we will get
  # the same email multiple times. Each time it is processed, we
  # will schedule all jobs, so to prevent dupes keep unique for
  # 20 min, scoped to from address and to token
  sidekiq_options unique: true, unique_job_expiration: 60 * 20,
    unique_args: :token_and_from, backtrace: 10

  def self.token_and_from(schedule_token, email)
    [schedule_token, email[:from]]
  end

  # take in schedule_token for uniqueness
  def perform(schedule_token, email)
    Rails.logger.info { "processing reminder for #{schedule_token} " <<
      email.to_s.inspect } 
    BumperMailer.return_reminder(email).deliver
  end
end
