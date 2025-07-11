# frozen_string_literal: true
# name: discourse-bump-on-edit-first-post
# about: Bumps topics with specific tags when the first post is edited
# version: 1.0.0
# authors: Jeffrey
# url: https://github.com/discourse/discourse-bump-on-edit-first-post
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :bump_on_first_post_edit_enabled

register_asset "stylesheets/common/bump-on-edit.scss"

PLUGIN_NAME ||= "discourse-bump-on-edit-first-post"

after_initialize do
  # Event handler for post editing
  DiscourseEvent.on(:post_edited) do |post, topic_changed, options|
    next unless post&.topic
    next unless post.post_number == 1

    BumpService.bump_topic(post.topic)
  end
end 