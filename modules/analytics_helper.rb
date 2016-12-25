include Staccato

# Wrapper for the staccato gem: https://github.com/tpitale/staccato
module AnalyticsHelper

  @tracker = Staccato.tracker(ENV['ANALYTICS_ID'])

  def self.track_event(category: nil, action: nil, label: nil, value: 0)
    # puts "#{@tracker.id}"
    @tracker.track(category: category, action: action, label: label, value: value)
  end

end
