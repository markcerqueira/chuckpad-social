class AbuseReport < ActiveRecord::Base

  # Given a patch, user id, and whether client requested to report abuse or not, an AbuseReport will be created
  # or deleted. If the client and server state are inconsistent, nothing will be done and a "success" result string
  # will be returned.
  def self.create_or_delete(patch, user_id, is_abuse)
    # See if a AbuseReport record already exists
    abuse_report = AbuseReport.where(patch_id: patch.id, user_id: user_id).first

    if abuse_report.nil? && is_abuse
      abuse_report = AbuseReport.new do |r|
        r.user_id = user_id
        r.patch_id = patch.id
        r.reported_at = Time.now
      end

      patch.abuse_count = patch.abuse_count + 1

      abuse_report.save
      patch.save

      return 'Patch abuse report received.'
    end

    if abuse_report.present? && !is_abuse
      abuse_report.delete

      patch.abuse_count = patch.abuse_count - 1
      patch.save

      return 'Patch abuse report rescinded.'
    end

    # Client and server state are somehow inconsistent
    return 'Patch abuse report received.'
  end

end
