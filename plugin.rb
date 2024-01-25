# name: localize-posts
# about: Adds lang attribute to posts content block
# version: 0.0.1
# authors: Awesome Plugin Developer
# url: https://github.com/CochOrg/discourse-reviewable-plugin

gem 'detect_language', '1.1.2'

Rails.application.config.before_initialize do
  # initialization code goes here
end

after_initialize do
  module ::LocalizePosts
    PLUGIN_NAME = "localize-posts"

    class Engine < ::Rails::Engine
      isolate_namespace LocalizePosts
    end
  end

  %w[
    lib/localize_posts/post_extension.rb
  ].each { |path| require_relative path }

  reloadable_patch do
    Post.class_eval { prepend LocalizePosts::PostExtension }
  end
end
