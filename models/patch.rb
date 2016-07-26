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
    # This can only happen if we allow deleting users. Do not allow deleting users?
    creator = User.get_user(id: creator_id)
    if creator.nil?
      creator_username = ''
    else
      creator_username = creator.username
    end

    {
        'id' => id,
        'name' => name,
        'featured' => featured,
        'documentation' => documentation,
        'hidden' => hidden, # Only creators of a particular patch will ever get back hidden => true
        'filename' => filename,
        'content_type' => content_type,
        'creator_id' => creator_id,
        'creator_username' => creator_username,
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
