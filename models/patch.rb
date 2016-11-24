class Patch < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'

  MINI_AUDICLE_TYPE = 1
  AURAGLYPH_TYPE = 2

  scope :hidden, -> { where(hidden: true) }
  scope :visible, -> { where(hidden: false) }

  scope :documentation, -> { where(documentation: true) }
  scope :visible_documentation, -> { self.documentation.visible }
  scope :hidden_documentation, -> { self.documentation.hidden }

  scope :featured, -> { where(featured: true) }
  scope :visible_featured, -> { self.featured.visible }
  scope :hidden_featured, -> { self.featured.hidden }

  scope :mini_audicle, -> { where(type: MINI_AUDICLE_TYPE) }
  scope :auraglyph, -> { where(type: AURAGLYPH_TYPE) }

  # Converts patch to json using to_hash method
  def as_json(options)
    to_hash()
  end

  # Returns patch object as a hash
  def to_hash()
    # TODO Check parent for visibility access in case it changes
    parentPatch = Patch.find_by_id(parent_id)
    patch_parent_id = -1
    unless parentPatch.nil?
      patch_parent_id = parent_id
    end

    {
        'id' => id,
        'name' => name,
        'description' => description,
        'featured' => featured,
        'documentation' => documentation,
        'hidden' => hidden, # Only creators of a particular patch will ever get back hidden => true
        'parent_id' => patch_parent_id,
        'filename' => filename,
        'creator_id' => creator_id,
        'creator_username' => User.get_user(id: creator_id).username,
        'created_at' => created_at.strftime('%Y-%m-%d %H:%M:%S'), # http://stackoverflow.com/a/9132422/265791
        'updated_at' => updated_at.strftime('%Y-%m-%d %H:%M:%S'),
        'download_count' => download_count,
        'abuse_count' => abuse_count,
        'resource' => '/patch/download/' + id.to_s
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
