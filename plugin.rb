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
    Rails.logger.info("Post edited event triggered for post #{post&.id}, post_number: #{post&.post_number}")
    
    next unless post&.topic
    Rails.logger.info("Post has topic: #{post.topic.id}")
    
    next unless post.post_number == 1
    Rails.logger.info("Post is first post, calling BumpService for topic #{post.topic.id}")

    result = BumpService.bump_topic(post.topic)
    Rails.logger.info("BumpService result: #{result} for topic #{post.topic.id}")
  end
end 