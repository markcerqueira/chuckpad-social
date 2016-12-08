class Patch < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'

  MINI_AUDICLE_TYPE = 1
  AURAGLYPH_TYPE = 2

  # File size limit for patch creation (see create_patch)
  MAX_PATCH_FILE_SIZE_KB = 10
  MAX_PATCH_FILE_SIZE_BYTES = MAX_PATCH_FILE_SIZE_KB * 1000

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

  # Helper method that creates a patch from the params given, saves it, and returns it.
  # Throws an error with a message if anything goes wrong during the creation process.
  #
  # Throws: PatchCreateError
  def self.create_patch(user, params)
    # Make sure file is below file size limit
    if File.size(params[:patch][:data][:tempfile]) > MAX_PATCH_FILE_SIZE_BYTES
      LogHelper.patch_log('create_patch', 'File size too large')
      raise PatchCreateError, "Patch file is too large. The maximum allowed is #{MAX_PATCH_FILE_SIZE_KB} KB."
    end

    patch_data = params[:patch][:data][:tempfile].read
    patch_data_digest = Digest::SHA256.hexdigest patch_data

    # Make sure the file uploaded has not already been uploaded by the user
    if Patch.where(creator_id: user.id, data_hash: patch_data_digest, patch_type: params[:patch][:type].to_i).present?
      LogHelper.patch_log('create_patch', 'User attempting to create patch with same data')
      raise PatchCreateError, 'A patch with this data has already been uploaded.'
    end

    # Create patch
    patch = Patch.new do |p|
      p.guid = SecureRandom.hex(12)
      p.name = params[:patch][:name]
      p.patch_type = params[:patch][:type].to_i

      if params[:patch].has_key?('hidden')
        p.hidden = params[:patch][:hidden]
      end

      p.description = params[:patch][:description]
      p.parent_guid = (params[:patch][:parent_guid] || nil)
      p.data = patch_data
      p.creator_id = user.id
      p.revision = 1
      p.created_at = DateTime.now.new_offset(0)
      p.updated_at = DateTime.now.new_offset(0)
      p.download_count = 0
      p.data_hash = patch_data_digest

      if params[:patch][:extra_data] != nil
        p.extra_data = params[:patch][:extra_data][:tempfile].read
      end

      if p.name.blank?
        p.name = ''
      end

      if p.description.blank?
        p.description = ''
      end
    end

    unless patch.save
      LogHelper.patch_log('create_patch', 'User attempting to create patch with same data')
      raise PatchCreateError
    end

    return patch
  end

  # Converts patch to json using to_hash method
  def as_json(options)
    to_hash()
  end

  # Returns patch object as a hash
  def to_hash()
    {
        'guid' => guid,
        'name' => name,
        'description' => description,
        'featured' => featured,
        'documentation' => documentation,
        'hidden' => hidden, # Only creators of a particular patch will ever get back hidden => true
        'creator_id' => creator_id,
        'creator_username' => User.get_user(id: creator_id).username,
        'created_at' => created_at.strftime('%Y-%m-%d %H:%M:%S'), # http://stackoverflow.com/a/9132422/265791
        'updated_at' => updated_at.strftime('%Y-%m-%d %H:%M:%S'),
        'download_count' => download_count,
        'abuse_count' => abuse_count,
        'resource' => '/patch/download/' + guid.to_s
    }.tap do |h|
      parent_patch = Patch.find_by_guid(parent_guid)
      if parent_patch.present? && !parent_patch.hidden
        h['parent_guid'] = parent_patch.guid
      end
    end
  end

end
