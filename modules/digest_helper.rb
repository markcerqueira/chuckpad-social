module DigestHelper

  # Method that validates digest in the params dictionary.
  # Throws an error with a message if anything goes wrong during the creation process.
  #
  # NOTE: Sinatra adds some non-request params to requests so be sure to call this with request.params and not just
  # params. https://github.com/sinatra/sinatra/issues/453
  #
  # Throws: DigestError
  def self.validate_digest(params)
    begin
      digest = ''
      params.sort.map do |key,value|
        # Skip over the 'digest' key
        unless key == 'digest'
          # Any multi-part uploads will be a Hash in the params Hash so skip those
          if value.is_a?(String)
            digest << key << value
          end
        end
      end

      unless params['digest'].casecmp(Digest::SHA256.hexdigest digest) == 0
        raise DigestError
      end
    rescue StandardError => error
      LogHelper.digest_helper('validate_digest', error.message)
      raise DigestError
    end
  end

end
