class BumperWorker
  include Sidekiq::Worker

  # If there are multiple reminders scheduled at once, we will get
  # the same email multiple times. Each time it is processed, we
  # will schedule all jobs, so to prevent dupes keep unique for
  # 20 min, scoped to from address and to token
  sidekiq_options unique: true, unique_job_expiration: 60 * 20

  # take in to_token for uniqueness
  def perform(to_token, email)
    BumperMailer.return_reminder(email).deliver
  end
end
