# frozen_string_literal: true

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