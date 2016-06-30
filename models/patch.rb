class Patch < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'

  scope :hidden, -> { where(hidden: true) }
  scope :visible, -> { where(hidden: false) }

  scope :documentation, -> { where(documentation: true) }
  scope :visible_documentation, -> { self.documentation.visible }
  scope :hidden_documentation, -> { self.documentation.hidden }

  scope :featured, -> { where(featured: true) }
  scope :visible_featured, -> { self.featured.visible }
  scope :hidden_featured, -> { self.featured.hidden }

  def creator_display_str
    if creator.nil?
      'Orphaned'
    else
      creator.display_str
    end
  end
end
