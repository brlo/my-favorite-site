# MergeRequest.create_indexes

class MergeRequest < ApplicationMongoRecord
  include Mongoid::Document

  # время создания можно получать из _id во так: id.generation_time
  field :p_id,       as: :page_id, type: BSON::ObjectId
  # автор
  field :u_id,       as: :user_id, type: BSON::ObjectId
  # Hash[column: {old: val, new: val]
  field :a_diff,     as: :attrs_diff, type: Hash
  # Информация по диффу больших текстовых полей:
  #
  # {
  #   <field_name>: {
  #     diffs: Array[groups['+', line, str]],
  #     # Сколько было строк в исходном тексте,
  #     # до применения патча (нужно для повторного рассчёта адресов новых строк)
  #     lines_count_was: 98,
  #     # Сколько строк добавили и удалили
  #     m_i: 1,
  #     p_i: 0,
  #   }
  # }
  field :diffs, type: Hash
  field :m_i,      as: :minus_i, type: Integer
  field :p_i,      as: :plus_i, type: Integer
  # Старое время редактирования исходного текста, к которому применяем патч (page.merged_at)
  field :src_ver, type: DateTime
  # Новоя время редактирования статьи, то есть время применения нашего патча (page.merged_at)
  field :dst_ver, type: DateTime
  # 1 - принято, 2 - ещё не обработано, 3 - отклонено.
  field :is_m,       as: :is_merged, type: Integer, default: 2
  # когда приняли или отклонили (вроде как дубль dst_ver, но пускай будет для верности)
  field :a_at,       as: :action_at, type: DateTime
  field :c_at,       as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at,       as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # MergeRequest.remove_undefined_indexes
  # MergeRequest.remove_indexes
  # MergeRequest.create_indexes
  index({is_merged: 1}, { background: true })
  index({page_id: 1},   { background: true })
  index({user_id: 1},   { background: true })

  belongs_to :page, foreign_key: 'p_id', primary_key: 'id'
  belongs_to :user, foreign_key: 'u_id', primary_key: 'id'

  scope :merged,   -> { where(is_merged: 1) }
  scope :waited,   -> { where(is_merged: 2) }
  scope :rejected, -> { where(is_merged: 0) }

  before_validation :normalize_attributes

  validates :page_id, :user_id, :src_ver, presence: true
  validate :text_or_attrs_diff_must_present
  validate :max_opened_count, on: [:create]

  after_create :chat_notify_create

  def max_opened_count
    return if self.user_id.nil?

    if self.user.merge_requests.waited.count > self.user.max_merge_requests_count
      self.errors.add(:id, 'Слишком большое число уже отправленных правок, ожидающих модерации. Надо подождать.')
    end
  end

  def attrs_for_render
    u = self.user
    pg = self.page
    h = {
      id: self.id.to_s,
      page_id: self.page_id.to_s,
      user_id: self.user_id.to_s,
      src_ver: self.src_ver&.strftime("%Y-%m-%d %H:%M:%S"),
      dst_ver: self.dst_ver&.strftime("%Y-%m-%d %H:%M:%S"),
      minus_i: self.minus_i,
      plus_i: self.plus_i,
      diffs: self.diffs,
      attrs_diff: self.attrs_diff,
      is_merged: self.is_merged.to_i,
      action_at: self.action_at&.strftime("%Y-%m-%d %H:%M:%S"),
      created_at: self.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at: self.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at_word: self.updated_at_word,
      user: {
        id: u.id.to_s,
        name: u.name,
        username: u.username,
      },
      page: {
        id: pg.id.to_s,
        is_published: pg.is_published,
        merge_ver: pg.merge_ver&.strftime("%Y-%m-%d %H:%M:%S"),
        page_type: pg.page_type.to_i,
        title: pg.title,
        title_sub: pg.title_sub,
        meta_desc: pg.meta_desc,
        path: pg.path,
        parent_id: pg.parent_id.to_s,
        lang: pg.lang,
        group_lang_id: pg.group_lang_id.to_s,
        body: pg.body,
        text_arrs: {body: [], references: []},
        tags_str: pg.tags&.join(', '),
        priority: pg.priority,
        created_at: pg.c_at,
        updated_at: pg.u_at,
      },
    }

    # когда rebase сделан, то изменения MR соответствуют тексту page, а поэтому
    # попробуем соседние строки в diff-е для удобства отрисовать во фронте
    if self.src_ver == pg.merge_ver
      h[:page][:text_arrs][:body] = pg.body_as_arr
      h[:page][:text_arrs][:references] = pg.references_as_arr
    end

    h
  end

  def self.create_mr!(user, page_id, page_params)
    page = ::Page.find_by!(id: page_id)

    mr = self.new()
    # автор
    mr.user_id = user.id

    # заполняем в mr все необходимые параметры
    ::DiffService.new(mr, page).fill_fields_on_new_merge_request(page_params)

    is_saved = mr.save
    is_saved ? mr : nil
  end

  def rebase!
    ::DiffService.new(self, self.page).rebase
    self.save
  end

  def merge!
    user = self.user
    pg = self.page

    ::DiffService.new(self, pg).merge
    is_saved = self.save

    # MR принят, поэтому надо в статью добавить нового редактора
    if is_saved
      pg.add_editor(user)
      pg.save!

      self.chat_notify_merge
    else
      puts '---------- ERROR on MergeRequest.merge! ------------'
      puts pg.errors.inspect
      puts '---------------------------------------'
    end

    is_saved
  end

  def reject!
    self.update!(is_merged: 0, action_at: DateTime.now.utc.round)
    self.save
  end

  def normalize_attributes
    self.u_at = DateTime.now.utc.round
  end

  def text_or_attrs_diff_must_present
    if self.attrs_diff.blank? && self.diffs.blank?
      self.errors.add(:id, 'Нельзя создать запрос правок, ничего не исправляя')
    end
  end

  private

  # уведомить чат о сздании MR:
  def chat_notify_create
    mr = self
    pg = self.page
    u = self.user

    msg  = "🚀 <b>#{u.name} (#{u.username})</b> предложил(а) <b><a href=\"https://edit.bibleox.com/merge_requests/#{mr.id.to_s}\">правки</a></b>"
    msg += " к статье: <b><a href=\"https://bibleox.com/ru/#{pg.lang}/w/#{pg.path}\">#{pg.title}</a></b>"
    ::TelegramBot.say(msg)
  end

  # уведомить чат о сздании MR:
  def chat_notify_merge
    mr = self
    pg = self.page
    u = self.user

    # уведомить чат о принятии MR:
    msg  = "✅ Приняты <b><a href=\"https://edit.bibleox.com/merge_requests/#{mr.id.to_s}\">правки</a></b>"
    msg += " к статье: <b><a href=\"https://bibleox.com/ru/#{pg.lang}/w/#{pg.path}\">#{pg.title}</a></b>."
    msg += " Модератор: #{u.name} (#{u.username})"
    ::TelegramBot.say(msg)
  end
end
