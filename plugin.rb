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

# Define BumpService inline
class BumpService
  class << self
    def bump_topic(topic)
      Rails.logger.info("BumpService.bump_topic called for topic #{topic&.id}")
      
      unless can_bump_topic?(topic)
        Rails.logger.info("Topic #{topic&.id} cannot be bumped")
        return false
      end

      begin
        Rails.logger.info("Updating bumped_at for topic #{topic.id}")
        topic.update_column(:bumped_at, Time.zone.now)
        Rails.logger.info("Successfully bumped topic #{topic.id}")
        true
      rescue => e
        Rails.logger.error("Failed to bump topic #{topic.id}: #{e.message}")
        false
      end
    end

    private

    def can_bump_topic?(topic)
      unless topic.present?
        Rails.logger.info("Cannot bump: topic is nil")
        return false
      end
      
      unless SiteSetting.bump_on_first_post_edit_enabled
        Rails.logger.info("Cannot bump: plugin is disabled")
        return false
      end
      
      unless has_allowed_tags?(topic)
        Rails.logger.info("Cannot bump topic #{topic.id}: no allowed tags")
        return false
      end
      
      if topic_in_excluded_category?(topic)
        Rails.logger.info("Cannot bump topic #{topic.id}: in excluded category")
        return false
      end
      
      Rails.logger.info("Topic #{topic.id} can be bumped")
      true
    end

    def has_allowed_tags?(topic)
      Rails.logger.info("Checking tags for topic #{topic.id}")
      
      unless topic.tags.present?
        Rails.logger.info("Topic #{topic.id} has no tags")
        return false
      end
      
      allowed_tags = SiteSetting.bump_allowed_tags.split('|')
      Rails.logger.info("Allowed tags: #{allowed_tags.inspect}")
      
      if allowed_tags.empty?
        Rails.logger.info("No allowed tags configured")
        return false
      end

      topic_tag_names = topic.tags.pluck(:name)
      Rails.logger.info("Topic #{topic.id} tags: #{topic_tag_names.inspect}")
      
      has_match = (topic_tag_names & allowed_tags).any?
      Rails.logger.info("Tag match result: #{has_match}")
      
      has_match
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
    Rails.logger.info("Post edited event triggered for post #{post&.id}, post_number: #{post&.post_number}")
    
    next unless post&.topic
    Rails.logger.info("Post has topic: #{post.topic.id}")
    
    next unless post.post_number == 1
    Rails.logger.info("Post is first post, calling BumpService for topic #{post.topic.id}")

    result = BumpService.bump_topic(post.topic)
    Rails.logger.info("BumpService result: #{result} for topic #{post.topic.id}")
  end
end 