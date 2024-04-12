# frozen_string_literal: true

module LocalizePosts
  module PostExtension
    def cook(raw, opts = {})
      # For some posts, for example those imported via RSS, we support raw HTML. In that
      # case we can skip the rendering pipeline.
      return raw if cook_method == Post.cook_methods[:raw_html]

      options = opts.dup
      options[:cook_method] = cook_method

      # A rule in our Markdown pipeline may have Guardian checks that require a
      # user to be present. The last editing user of the post will be more
      # generally up to date than the creating user. For example, we use
      # this when cooking #hashtags to determine whether we should render
      # the found hashtag based on whether the user can access the category it
      # is referencing.
      options[:user_id] = self.last_editor_id
      options[:omit_nofollow] = true if omit_nofollow?

      if self.should_secure_uploads?
        each_upload_url do |url|
          uri = URI.parse(url)
          if FileHelper.is_supported_media?(File.basename(uri.path))
            raw =
              raw.sub(
                url,
                Rails.application.routes.url_for(
                  controller: "uploads",
                  action: "show_secure",
                  path: uri.path[1..-1],
                  host: Discourse.current_hostname,
                  ),
                )
          end
        end
      end

      cooked = post_analyzer.cook(raw, options)

      new_cooked = Plugin::Filter.apply(:after_post_cook, self, cooked)

      if post_type == Post.types[:regular]
        if new_cooked != cooked && new_cooked.blank?
          Rails.logger.debug("Plugin is blanking out post: #{self.url}\nraw: #{raw}")
        elsif new_cooked.blank?
          Rails.logger.debug("Blank post detected post: #{self.url}\nraw: #{raw}")
        end
      end

      begin
        DetectLanguage.configure do |config|
          config.api_key = SiteSetting.detect_language_api_key

          # enable secure mode (SSL) if you are passing sensitive data
          # config.secure = true
        end

        lang = DetectLanguage.simple_detect(raw)

        new_cooked = "<div lang=\"#{lang}\">#{new_cooked}</div>"
      rescue
        nil
      end

      new_cooked
    end
  end
end
