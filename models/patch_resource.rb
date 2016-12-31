class PatchResource < ActiveRecord::Base

  # Helper method that creates a patch resource object.
  def self.create_patch_resource(patch_guid, data)
    existing_resources = get_resources(patch_guid)

    resource = PatchResource.new do |resource|
      resource.patch_guid = patch_guid

      # First resource will have version = 0, otherwise it will be version + 1
      resource.version = existing_resources.present? ? existing_resources.size + 1 : 0

      resource.data = data
      resource.created_at = DateTime.now.new_offset(0)
    end

    resource.save
  end

  # Helper method that gets the most recent data for the given patch GUID. Throws a PatchNotFoundError if no
  # resource can be found.
  #
  # Throws: PatchNotFoundError
  def self.get_most_recent_resource(patch_guid)
    most_recent_resource = PatchResource.where(patch_guid: patch_guid).order(:version).last

    if most_recent_resource.nil?
      raise PatchNotFoundError
    end

    return most_recent_resource
  end

  # Returns list of all patch resources ordered by version ascending (i.e. version 1 first, version 2 next, etc)
  def self.get_resources(patch_guid)
    return PatchResource.where(patch_guid: patch_guid).order(:version)
  end

  # Converts patch resource to json using to_hash method
  def as_json(options)
    to_hash()
  end

  # Returns patch resource object as a hash
  def to_hash()
    {
        'guid' => patch_guid,
        'version' => version,
        'created_at' => created_at.strftime('%Y-%m-%d %H:%M:%S'), # http://stackoverflow.com/a/9132422/265791
    }
  end

end
