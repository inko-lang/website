# frozen_string_literal: true

require 'etc'
require 'http'
require 'json'
require 'mime/types'
require 'mini_magick'
require 'parallel'
require 'tempfile'
require 'yaml'
require 'pathname'

class SponsorData
  class Image
    DIRECTORY =
      Pathname.new(File.expand_path('../source/images/sponsors', __dir__))

    def initialize(id, url)
      @id = id
      @url = url
    end

    def download
      response = HTTP.get(@url)

      if response.code != 200
        raise "Failed to download #{@url}: #{response.reason}"
      end

      path = local_path_for(response)
      body = response.body

      File.open(path, 'wb') do |file|
        while (data = body.readpartial)
          file.write(data)
        end
      end

      path
    end

    def local_path_for(response)
      content_type = response.headers['Content-Type']
      mime = MIME::Types[content_type].fetch(0)

      DIRECTORY.join("#{@id}.#{mime.preferred_extension}")
    end
  end

  URL = 'https://opencollective.com/%<project>s/members.json'
  ROOT = Pathname.new(File.expand_path('..', __dir__))
  SOURCE = ROOT.join('source')
  YAML_FILE = ROOT.join('data/sponsors.yml')
  WIDTH = '100'

  def initialize(project)
    @project = project
  end

  def update
    sponsors = sponsors_per_tier

    sponsors.each do |_, members|
      Parallel.each(members, in_threads: Etc.nprocessors) do |member|
        download_and_resize_image(member)
      end
    end

    File.open(YAML_FILE, 'w') do |file|
      file.write(YAML.dump(sponsors))
    end
  end

  def prune_logos
    yaml = YAML.safe_load(File.read(YAML_FILE))
    keep = Set.new

    yaml.each do |_, members|
      members.each do |member|
        next if member['image'].nil?

        image = File.basename(member['image'])

        keep << image if image
      end
    end

    Dir[Image::DIRECTORY.join('*.*')].each do |file|
      name = File.basename(file)

      File.unlink(file) unless keep.include?(name)
    end
  end

  def sponsors_per_tier
    per_tier = Hash.new { |hash, key| hash[key] = [] }

    api_data.each do |member|
      tier = member['tier']

      next if !tier || !member['isActive']

      per_tier[tier] << {
        'id' => member['MemberId'],
        'name' => member['name'],
        'image' => member['image'],
        'website' => member['website'],
        'total_donated' => member['totalAmountDonated'],
        'created_at' => member['createdAt']
      }
    end

    per_tier
  end

  def project_url
    format(URL, project: @project)
  end

  def api_data
    response = HTTP.get(project_url)

    if response.status != 200
      raise "Failed to obtain the data from Open Collective: #{response.reason}"
    end

    JSON.parse(response.body.to_s)
  end

  def download_and_resize_image(member)
    member['image'] =
      if (path = download_image(member))
        MiniMagick::Image.new(path).resize(WIDTH)

        path.relative_path_from(SOURCE).to_s
      end
  end

  def download_image(member)
    return if member['image'].nil? || member['image'].empty?

    Image.new(member['id'], member['image']).download
  end
end
