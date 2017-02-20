# REBIRTH_TODO: RSS?
class Draft < ActiveRecord::Base
  # Associations
  belongs_to :article
  belongs_to :user

  has_and_belongs_to_many :authors

  # Representations
  serialize :chunks

  enum web_status: [:web_draft, :web_published, :web_ready]
  enum print_status: [:print_draft, :print_ready]

  WEB_STATUS_NAMES = {
    web_draft: 'Draft',
    web_published: 'Published on the web',
    web_ready: 'Ready for web'
  }

  validates :headline, presence: true, length: {minimum: 2}
  validates :user, presence: true
  validates :article, presence: true
  validates :headline, not_nil: true
  validates :subhead, not_nil: true
  validates :bytitle, not_nil: true
  validates :lede, not_nil: true
  validates :attribution, not_nil: true
  validates :redirect_url, not_nil: true
  validates :chunks, not_nil: true
  validates :web_template, not_nil: true

  validate :tag_list_is_valid

  acts_as_ordered_taggable

  # Callbacks
  before_save :normalize_fields
  before_save :fill_lede

  # Keyword search
  scope :search_query, lambda { |q|
    return nil if q.blank?

    terms = q.downcase.split(/\s+/).map { |e|
      ('%' + e.gsub('*', '%') + '%').gsub(/%+/, '%')
    }

    num_or_conds = 3
    where(
      terms.map { |t|
        "(LOWER(drafts.headline) LIKE ? OR LOWER(drafts.subhead) LIKE ? OR LOWER(drafts.bytitle) LIKE ?)"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  def primary_tag(html)

  end

  # Content parsing and rendering
  # HTML <=> web_template + chunks
  def html=(html)
    require 'parser'
    parser = Techplater::Parser.new(html)
    parser.parse!

    self.chunks = parser.chunks
    self.web_template = parser.web_template
  end

  def html
    require 'renderer'
    renderer = Techplater::Renderer.new(self.web_template, self.chunks)
    renderer.render
  end

  # Tag-related functionalities
  NO_PRIMARY_TAG = 'NO_PRIMARY_TAG'

  def primary_tag
    self.tag_list.first == NO_PRIMARY_TAG ?
      "" :
      self.tag_list.first
  end

  def secondary_tags
    self.tag_list.drop(1).join(", ")
  end

  def primary_tag=(primary_tag)
    primary_tag.present? ?
      self.tag_list[0] = primary_tag.upcase :
      self.tag_list[0] = NO_PRIMARY_TAG
  end

  def secondary_tags=(secondary_tags)
    self.tag_list = [self.tag_list[0]] + secondary_tags.split(",").map(&:strip).map(&:upcase)
  end

  # Readable authors string
  def authors_string
    author_names = self.authors.map(&:name)

    case author_names.size
    when 0
      "Unknown Author"
    when 1
      authors.first.name
    when 2
      "#{authors.first.name} and #{authors.last.name}"
    when 3
      (authors[0...-1].map(&:name) + ["and #{authors.last.name}"]).join(", ")
    end
  end

  private
    def normalize_fields
      self.headline.strip!
      self.subhead.strip!
      self.bytitle.strip!
      self.lede.strip!
      self.attribution.strip!

      if self.redirect_url.present?
        (self.redirect_url = "http://" + self.redirect_url) unless self.redirect_url =~ /^http/
      end
    end

    def fill_lede
      if self.lede.blank?
        return if self.chunks.empty?
        self.lede = Nokogiri::HTML.fragment(self.chunks.first).text
      end
    end

    # This ensures that we at least have 1 tag as the primary tag
    # For Article without a primary tag, the first tag should be NO_PRIMARY_TAG
    def tag_list_is_valid
      errors.add(:base, "Invalid tag list: No primary tag slot. ") unless self.tag_list.size >= 1
    end
end
