# frozen_string_literal: true

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