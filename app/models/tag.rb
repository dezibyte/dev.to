class Tag < ActsAsTaggableOn::Tag
  acts_as_followable

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :text_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_blank: true
  validates :bg_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_blank: true


  validate :validate_alias
  before_validation :evaluate_markdown
  before_validation :pound_it
  before_save :calculate_hotness_score
  after_save :bust_cache

  def submission_template_customized(param_0 = nil)
    submission_template.gsub("PARAM_0", param_0)
  end

  private

  def evaluate_markdown
    self.rules_html = MarkdownParser.new(rules_markdown).evaluate_markdown
    self.wiki_body_html = MarkdownParser.new(wiki_body_markdown).evaluate_markdown
  end

  def calculate_hotness_score
    self.hotness_score = Article.tagged_with(name).
      where("articles.featured_number > ?", 7.days.ago.to_i).
      map do |a|
        (a.comments_count * 14) + (a.reactions_count * 4) + rand(6) + ((taggings_count + 1 ) / 2)
      end.
      sum
  end

  def bust_cache
    CacheBuster.new.bust("/t/#{name}")
    CacheBuster.new.bust("/t/#{name}?i=i")
    CacheBuster.new.bust("/t/#{name}/?i=i")
    CacheBuster.new.bust("/t/#{name}/")
    CacheBuster.new.bust("/tags")
  end

  def validate_alias
    if alias_for.present? && !Tag.find_by_name(alias_for)
      errors.add(:tag, "alias_for must refer to existing tag")
    end
  end

  def pound_it
    text_color_hex&.prepend("#") unless text_color_hex&.starts_with?("#")
    bg_color_hex&.prepend("#") unless bg_color_hex&.starts_with?("#")
  end
end