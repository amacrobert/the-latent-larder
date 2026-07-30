# Filters for the things schema.org wants in a machine format but that the
# recipe front matter, quite rightly, keeps in a human one. Recipes are written
# with "1 hr 30 min" and a photo path; Google wants "PT1H30M" and pixel
# dimensions. Converting at build time means neither the author nor the
# templates have to think about it.

module TheLatentLarder
  module SEOFilters
    # "1 hr 30 min" -> "PT1H30M". Tolerates the parenthetical and trailing
    # notes the times sometimes carry ("4 hrs (freezing)", "1 hr chill") by
    # only ever looking at the numbers attached to an hour or minute unit.
    # Returns nil when there is nothing numeric to find, so the caller can omit
    # the property rather than emit a meaningless "PT0S".
    def iso8601_duration(input)
      return nil if input.nil?

      minutes = duration_in_minutes(input)
      minutes.zero? ? nil : minutes_to_iso8601(minutes)
    end

    # Sum of two duration strings, in the same ISO format. Used for totalTime,
    # which Google treats as its own field rather than deriving.
    def iso8601_total(first, second)
      minutes = duration_in_minutes(first) + duration_in_minutes(second)
      minutes.zero? ? nil : minutes_to_iso8601(minutes)
    end

    # Intrinsic pixel dimensions of an image in the source tree, so <img> can
    # carry width/height and the browser can reserve the box before the bytes
    # arrive. Reads the file header directly — no image library, no gem.
    def image_width(path)
      image_dimensions(path)&.first
    end

    def image_height(path)
      image_dimensions(path)&.last
    end

    # The image a Pinterest save should use: the 2:3 "-tall" crop that
    # bin/resize-recipe-image writes alongside the wide one. Pinterest lays its
    # feed out in fixed-width columns, so a landscape photo takes a third of the
    # height — and a third of the attention — of a portrait one.
    #
    # Falls back to the wide image when no crop has been made yet, so a recipe
    # photographed before the crop existed still pins something rather than
    # nothing.
    def pin_image(path)
      return nil if path.nil? || path.empty?

      tall = path.sub(/(\.[^.\/]+)\z/, '-tall\1')
      image_dimensions(tall) ? tall : path
    end

    # Size on disk, for the length attribute RSS requires on <enclosure>. Not
    # optional in the spec, and a wrong number is worse than none: a reader that
    # trusts it will stop reading the image short.
    def image_bytes(path)
      return nil if path.nil? || path.empty?

      file = absolute_source_path(path)
      File.file?(file) ? File.size(file) : nil
    end

    private

    def duration_in_minutes(input)
      text = input.to_s.downcase
      hours = text[/(\d+)\s*(?:h|hr|hrs|hour|hours)\b/, 1].to_i
      mins  = text[/(\d+)\s*(?:m|min|mins|minute|minutes)\b/, 1].to_i
      (hours * 60) + mins
    end

    def minutes_to_iso8601(minutes)
      hours, mins = minutes.divmod(60)
      duration = +"PT"
      duration << "#{hours}H" if hours.positive?
      duration << "#{mins}M" if mins.positive?
      duration
    end

    # Cached per build: a 29-recipe home page asks for the same handful of
    # files repeatedly, and each miss is a disk read.
    def image_dimensions(path)
      return nil if path.nil? || path.empty?

      @dimension_cache ||= {}
      @dimension_cache.fetch(path) do
        @dimension_cache[path] = read_dimensions(absolute_source_path(path))
      end
    end

    def absolute_source_path(path)
      site = @context.registers[:site]
      File.join(site.source, path.sub(%r{\A/}, ""))
    end

    def read_dimensions(file)
      return nil unless File.file?(file)

      header = File.binread(file, 64).to_s
      # Compared as bytes rather than matched with a regex on purpose: the four
      # length bytes between "RIFF" and "WEBP" are arbitrary, and any of them
      # can be 0x0A — which a `.` in a regex will not match.
      if header.start_with?("\x89PNG\r\n\x1a\n".b)
        png_dimensions(header)
      elsif header.start_with?("RIFF".b) && header[8, 4] == "WEBP".b
        webp_dimensions(header)
      elsif header.start_with?("\xFF\xD8".b)
        jpeg_dimensions(file)
      end
    rescue StandardError
      # A malformed image should cost the site an attribute, not the build.
      nil
    end

    def png_dimensions(header)
      header[16, 8].unpack("N2")
    end

    # WebP stores dimensions differently per encoding: lossy ("VP8 ") keeps
    # them as two 14-bit fields, lossless ("VP8L") packs both into one 32-bit
    # word off by one, and extended ("VP8X") uses 24-bit values, also off by
    # one.
    def webp_dimensions(header)
      case header[12, 4]
      when "VP8 "
        w, h = header[26, 4].unpack("v2")
        [w & 0x3fff, h & 0x3fff]
      when "VP8L"
        bits = header[21, 4].unpack1("V")
        [(bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1]
      when "VP8X"
        w = header[24, 3].unpack1("v") | (header[26].ord << 16)
        h = header[27, 3].unpack1("v") | (header[29].ord << 16)
        [(w & 0xffffff) + 1, (h & 0xffffff) + 1]
      end
    end

    # JPEG has no fixed-offset size; it has to be found by walking the segment
    # markers to a start-of-frame.
    def jpeg_dimensions(file)
      File.open(file, "rb") do |io|
        io.read(2) # SOI
        while (marker = io.read(2))
          break unless marker.getbyte(0) == 0xFF

          code = marker.getbyte(1)
          length = io.read(2).unpack1("n")
          # SOF0-SOF15, excluding the non-frame markers in that range.
          if (0xC0..0xCF).cover?(code) && ![0xC4, 0xC8, 0xCC].include?(code)
            io.read(1) # precision
            height, width = io.read(4).unpack("n2")
            return [width, height]
          end

          io.seek(length - 2, IO::SEEK_CUR)
        end
      end
      nil
    end
  end
end

Liquid::Template.register_filter(TheLatentLarder::SEOFilters)
