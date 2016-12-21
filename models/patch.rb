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
    if params[:patch_data].nil?
      LogHelper.patch_log('create_patch', 'Patch data is required for creating a patch')
      raise PatchCreateError, "Some data is required to create a patch."
    end

    # Make sure file is below file size limit
    if File.size(params[:patch_data][:tempfile]) > MAX_PATCH_FILE_SIZE_BYTES
      LogHelper.patch_log('create_patch', 'Patch data is too large')
      raise PatchCreateError, "Patch file is too large. The maximum allowed is #{MAX_PATCH_FILE_SIZE_KB} KB."
    end

    if File.size(params[:patch_data][:tempfile]) == 0
      LogHelper.patch_log('create_patch', 'Patch data is empty')
      raise PatchCreateError, "File contains no data. Please upload some data with your patch."
    end

    if params[:patch_extra_data] != nil
      if File.size(params[:patch_extra_data][:tempfile]) > MAX_PATCH_FILE_SIZE_BYTES
        LogHelper.patch_log('create_patch', 'Patch extra data is large')
        raise PatchCreateError, "Extra data for this patch is too large. The maximum allowed is #{MAX_PATCH_FILE_SIZE_KB} KB."
      end
    end

    patch_data = params[:patch_data][:tempfile].read
    patch_data_digest = Digest::SHA256.hexdigest patch_data

    # Make sure the file uploaded has not already been uploaded by the user
    if Patch.where(creator_id: user.id, data_hash: patch_data_digest, patch_type: params[:patch_type].to_i).present?
      LogHelper.patch_log('create_patch', 'User attempting to create patch with same data')
      raise PatchCreateError, 'A patch with this data has already been uploaded.'
    end

    # Create patch
    patch = Patch.new do |p|
      p.guid = SecureRandom.hex(12)
      p.name = (params[:patch_name] || '')
      p.description = (params[:patch_description] || '')
      p.patch_type = params[:patch_type].to_i
      p.parent_guid = (params[:patch_parent_guid] || nil)
      p.data = patch_data
      p.creator_id = user.id
      p.revision = 1
      p.created_at = DateTime.now.new_offset(0)
      p.updated_at = DateTime.now.new_offset(0)
      p.download_count = 0
      p.data_hash = patch_data_digest

      if params[:patch_hidden].present?
        p.hidden = params[:patch_hidden]
      end

      if params[:patch_extra_data] != nil
        p.extra_data = params[:patch_extra_data][:tempfile].read
      end
    end

    unless patch.save
      LogHelper.patch_log('create_patch', 'User attempting to create patch with same data')
      raise PatchCreateError
    end

    return patch
  end

  # Updates the patch this method is called on with inputs from the given params hash.
  # Throws an error with a message if anything goes wrong during the update process.
  #
  # Throws: PatchUpdateError
  def update_patch(params)
    data = params[:patch_data]
    unless data.nil?
      if File.size(params[:patch_data][:tempfile]) == 0
        LogHelper.patch_log('update_patch', 'data provided is zero-length')
        raise PatchUpdateError, 'Patch cannot be updated with empty data. Please try again.'
      end

      self.data = params[:patch_data][:tempfile].read
      self.data_hash = Digest::SHA256.hexdigest patch.data
      revision_made = true
    end

    name = params[:patch_name]
    unless name.nil? || name.empty?
      self.name = name
      revision_made = true
    end

    hidden = params[:patch_hidden]
    unless hidden.nil? || hidden.empty?
      self.hidden = hidden
      revision_made = true
    end

    description = params[:patch_description]
    unless description.nil? || description.empty?
      self.description = description
      revision_made = true
    end

    if revision_made
      self.updated_at = DateTime.now.new_offset(0)
      self.revision = self.revision + 1
      self.save
    end
  end

  # Returns the patch with the given guid. Throws an error with a message if no patch is found.
  #
  # Throws: PatchNotFoundError
  def self.get_patch(guid)
    patch = Patch.find_by_guid(guid)
    if patch.nil?
      raise PatchNotFoundError
    end
    return patch
  end

  # Finds the user and the patch specified in the params and ensures that the patch specified can be modified by the
  # user specified. Throws an error if any of the aforementioned operations fail.
  #
  # Throws: UserNotFoundError, AuthTokenInvalidError, PatchNotFoundError, PatchPermissionError
  def self.get_modifiable_patch(request, params)
    current_user = User.get_user_from_params(request, params)
    patch = Patch.get_patch(params[:guid])
    if current_user.id != patch.creator_id
      raise PatchPermissionError
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
      if parent_guid.present?
        parent_patch = Patch.find_by_guid(parent_guid)
        if parent_patch.present? && !parent_patch.hidden
          h['parent_guid'] = parent_patch.guid
        end
      end

      if extra_data.present?
        h['extra_resource'] = '/patch/download/extra/' + guid.to_s
      end
    end
  end

end
