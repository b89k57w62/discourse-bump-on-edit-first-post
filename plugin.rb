# frozen_string_literal: true
# name: discourse-bump-on-edit-first-post
# about: Bumps topics with specific tags when the first post is edited
# version: 1.0.0
# authors: Jeffrey
# url: https://github.com/b89k57w62/discourse-bump-on-edit-first-post
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :bump_on_first_post_edit_enabled

register_asset "stylesheets/common/bump-on-edit.scss"

PLUGIN_NAME ||= "discourse-bump-on-edit-first-post"

# Define BumpService inline
class BumpService
  class << self
    def bump_topic(topic)
      return false unless can_bump_topic?(topic)

      begin
        topic.update_column(:bumped_at, Time.zone.now)
        true
      rescue => e
        Rails.logger.error("Failed to bump topic #{topic.id}: #{e.message}")
        false
      end
    end

    private

    def can_bump_topic?(topic)
      return false unless topic.present?
      return false unless SiteSetting.bump_on_first_post_edit_enabled
      return false unless has_allowed_tags?(topic)
      return false if topic_in_excluded_category?(topic)
      
      true
    end

    def has_allowed_tags?(topic)
      return false unless topic.tags.present?
      
      allowed_tags = SiteSetting.bump_allowed_tags.split('|')
      return false if allowed_tags.empty?

      topic_tag_names = topic.tags.pluck(:name)
      (topic_tag_names & allowed_tags).any?
    end

    def topic_in_excluded_category?(topic)
      return false if SiteSetting.bump_exclude_categories.blank?
      
      excluded_categories = SiteSetting.bump_exclude_categories.split('|')
      excluded_categories.include?(topic.category_id.to_s)
    end
  end
end

after_initialize do
  # Event handler for post editing
  DiscourseEvent.on(:post_edited) do |post, topic_changed, options|
    next unless post&.topic
    next unless post.post_number == 1

    BumpService.bump_topic(post.topic)
  end
end 