class Patch < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'

  def creator_display_str
    if creator.nil?
      'Orphaned'
    else
      creator.display_str
    end
  end
end
