class Tag < ActiveRecord::Base
  belongs_to :blog
  has_and_belongs_to_many :articles, order: 'created_at DESC', join_table: 'articles_tags'

  validates :name, uniqueness: { scope: :blog_id }
  validates :blog, presence: true
  validates :name, presence: true

  before_validation :ensure_naming_conventions

  attr_accessor :description, :keywords

  def self.create_from_article!(article)
    return if article.keywords.nil?
    tags = []
    Tag.transaction do
      tagwords = article.keywords.to_s.scan(/((['"]).*?\2|[\.:[[:alnum:]]]+)/).map do |x|
        x.first.tr("\"'", '')
      end
      tagwords.uniq.each do |tagword|
        tagname = tagword.to_url
        tags << article.blog.tags.find_or_create_by(name: tagname) do |tag|
          tag.display_name = tagword
        end
      end
    end
    article.tags = tags
    tags
  end

  def ensure_naming_conventions
    self.display_name = name if display_name.blank?
    self.name = display_name.to_url unless display_name.blank?
  end

  def self.find_all_with_article_counters
    Tag.joins(:articles).
      where(contents: { published: true }).
      select(*Tag.column_names, 'COUNT(articles_tags.article_id) as article_counter').
      group(*Tag.column_names).
      order('article_counter DESC').limit(1000)
  end

  def self.find_with_char(char)
    where('name LIKE ? ', "%#{char}%").order('name ASC')
  end

  def self.collection_to_string(tags)
    tags.map(&:display_name).sort.map { |name| name =~ / / ? "\"#{name}\"" : name }.join ', '
  end

  def published_articles
    articles.already_published
  end

  def permalink
    name
  end

  def permalink_url(_anchor = nil, only_path = false)
    blog.url_for(controller: 'tags', action: 'show', id: permalink, only_path: only_path)
  end
end
