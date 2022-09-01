class Stih
  include Mongoid::Document

  # book
  # chapter
  # number
  # text

  # код книги
  field :book, type: String
  # номер главы
  field :ch,   as: :chapter, type: Integer
  # номер стиха
  field :num,  as: :number, type: Integer
  # текст стиха
  field :text, type: String
  # источник (масортский, LXX)
  field :s, as: :source,  type: Integer
  # запасное поле для параметров
  field :data, type: Hash
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # bundle exec rake db:mongoid:create_indexes
  index({book: 1, ch: 1},               {background: true})
  index({book: 1, ch: 1, num: 1},       {unique: true, background: true})
  index({text: 'text'},                  {background: true})
  # index({int_id: 1},     {unique: true, background: true})
  # index({c_at: -1},                    {background: true})
  # index({r_id: 1},                     {background: true})
  # index({r_type: 1},                   {background: true})
  # index({r: 1},                        {background: true})
  # index({r_id: 1, r_type: 1, kind: 1}, {background: true})
  # index({'data.conversation_id': 1},   {background: true})

  SOURCES_BY_ID = {
    1  => 'main',
    2  => 'additional'
  }.freeze

  SOURCES_BY_NAME = SOURCES_BY_ID.invert.freeze

  # scope :for_list_view,     -> { without(:email_subject_message, :email_message, :sms_message, :push_android_message, :push_ios_message) }
  # scope :recently,          -> { order(created_at: :desc) }
  # scope :unread,            -> { where(is_read: false) }
  # scope :only_common_kinds, -> { where(:kind.nin => SPECIFIC_KINDS_IDS) }
  # scope :only_ios_kinds,    -> { where(kind: { '$in': SPECIFIC_KINDS_IDS }) }

  # scope :for_support_conversation, lambda { |conversation = nil|
  #   rel = where(kind: Notification::KINDS_BY_NAME['conversation_message_received'])
  #   rel = rel.where('data.conversation_id': conversation.id.to_s) if conversation
  #   rel
  # }
  # scope :for_users_conversation, lambda { |conversation = nil|
  #   rel = where(kind: Notification::KINDS_BY_NAME['conversation_new_msg'])
  #   rel = rel.where('data.conversation_id': conversation.id.to_s) if conversation
  #   rel
  # }

  validates :book, :ch, :num, :text, :source, presence: true
  validates :source, inclusion: {in: SOURCES_BY_ID.keys }

  before_create :set_id_if_nil

  def set_int_id_if_nil
    self.int_id = self.class.allocate_int_id! if self.int_id.nil?
  end

  def set_id_if_nil
    if self._id.nil?
      if book && ch && num
        self._id = "#{book}:#{ch}:#{num}"
      else
        raise('stih must contain Book, Chapter and Number')
      end
    end
  end
end
