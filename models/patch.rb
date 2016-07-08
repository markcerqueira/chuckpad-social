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

  # Converts patch to json using to_hash method
  def as_json(options)
    to_hash()
  end

  # Returns patch object as a hash
  def to_hash()
    {
        'id' => id,
        'name' => name,
        'featured' => featured,
        'documentation' => documentation,
        'hidden' => hidden, # Only creators of a particular patch will ever get back hidden => true
        'filename' => filename,
        'content_type' => content_type,
        'creator_id' => creator_id,
        'creator_username' => User.get_user(creator_id).username,
        'resource' => '/patch/show/' + id.to_s
    }
  end

  def creator_display_str
    if creator.nil?
      'Orphaned'
    else
      creator.display_str
    end
  end
end
