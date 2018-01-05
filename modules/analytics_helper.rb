include Staccato

# Wrapper for the staccato gem: https://github.com/tpitale/staccato
module AnalyticsHelper

  @tracker = Staccato.tracker(ENV['ANALYTICS_ID'])

  # Called to track events under the 'live' category
  def self.track_live_event(action: nil, params: nil)
    track_event(category: 'live', action: action, params: params)
  end

  # Called to track events under the 'patch' category
  def self.track_patch_event(action: nil, params: nil)
    track_event(category: 'patch', action: action, params: params)
  end

  # Called to track events under the 'user' category
  def self.track_user_event(action: nil, params: nil)
    track_event(category: 'user', action: action, params: params)
  end

  # Internal method that sends event to Google Analytics
  def self.track_event(category: nil, action: nil, params: params)
    Thread::new do
      begin
        @tracker.event(category: category, action: "#{action}-#{Patch.patch_type_to_string(params)}")
      rescue StandardError => error
        LogHelper.analytics_helper('track_event', error.message)
      end
    end
  end

end
