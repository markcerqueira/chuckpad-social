module DigestHelper

  RANDOM_VALUE_KEY = 'random'
  DIGEST_VALUE_KEY = 'digest'

  # Volatile hash constants
  HASH_TIME_TO_LIVE = 300 # 5 minutes in seconds
  HASH_CLEANUP_LENGTH = 2000 # After we hit this number of random values we'll clean-up our hash and remove expired elements

  @seen_random_cache = Vash.new

  # Method that validates digest in the params dictionary.
  # Throws an error with a message if anything goes wrong during the creation process.
  #
  # NOTE: Sinatra adds some non-request params to requests so be sure to call this with request.params and not just
  # params. https://github.com/sinatra/sinatra/issues/453
  #
  # Throws: DigestError
  def self.validate_digest(params)
    begin
      if @seen_random_cache[params[RANDOM_VALUE_KEY]].present?
        LogHelper.digest_helper('validate_digest', 'Random value has already been seen')
        raise DigestError
      end

      # It's a hash but we really are using it as a set so just put a '1' in to mark it as 'seen'
      @seen_random_cache[params[RANDOM_VALUE_KEY], HASH_TIME_TO_LIVE] = '1'

      if @seen_random_cache.length > HASH_CLEANUP_LENGTH
        @seen_random_cache.cleanup!
        LogHelper.digest_helper('validate_digest', "Cleaning up @seen_random_cache. New size is #{@seen_random_cache.length}")
      end

      digest = ''
      params.sort.map do |key,value|
        # Skip over the 'digest' key
        unless key == DIGEST_VALUE_KEY
          # Any multi-part uploads will be a Hash in the params Hash so skip those
          if value.is_a?(String)
            digest << key << value
          end
        end
      end

      unless params[DIGEST_VALUE_KEY].casecmp(Digest::SHA256.hexdigest digest) == 0
        raise DigestError
      end
    rescue StandardError => error
      LogHelper.digest_helper('validate_digest', error.message)
      raise DigestError
    end
  end

end
