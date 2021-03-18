# frozen_string_literal: true

module Sponsors
  class Image
    SOURCE = Pathname.new(File.expand_path('../../source', __dir__))
    DIRECTORY = SOURCE.join('images', 'sponsors')
    WIDTH = '100'

    def initialize(id, url)
      @id = id
      @url = url
    end

    def download
      response = HTTP.get(@url)

      unless response.code == 200
        raise "Failed to download #{@url}: #{response.reason}"
      end

      path = local_path_for(response)
      remote_modified = Time.parse(response.headers['Last-Modified'])
      log_output = `git log -1 --format=%ad #{path} 2>&1`.strip

      update =
        if $?.success?
          Time.parse(log_output) < remote_modified
        else
          true
        end

      body = response.body

      if update
        File.open(path, 'wb') do |file|
          while (data = body.readpartial)
            file.write(data)
          end
        end

        MiniMagick::Image.new(path).resize(WIDTH)
      end

      path.relative_path_from(SOURCE).to_s
    end

    def local_path_for(response)
      content_type = response.headers['Content-Type']
      mime = MIME::Types[content_type].fetch(0)

      DIRECTORY.join("#{@id}.#{mime.preferred_extension}")
    end
  end
end
