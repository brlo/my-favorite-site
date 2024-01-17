# MergeRequest.create_indexes

class MergeRequest < ApplicationMongoRecord
  include Mongoid::Document

  # время создания можно получать из _id во так: id.generation_time
  field :p_id,       as: :page_id, type: BSON::ObjectId
  # автор
  field :u_id,       as: :user_id, type: BSON::ObjectId
  # Hash[column: {old: val, new: val]
  field :a_diff,     as: :attrs_diff, type: Hash
  # Array[groups['+', line, str]]
  field :t_diffs,     as: :text_diffs, type: Array
  # Сколько строк добавили и удалили
  field :p_i,        as: :plus_i, type: Integer
  field :m_i,        as: :minus_i, type: Integer
  # Старое время редактирования исходного текста, к которому применяем патч (page.merged_at)
  field :src_ver, type: DateTime
  # Новоя время редактирования статьи, то есть время применения нашего патча (page.merged_at)
  field :dst_ver, type: DateTime
  # Сколько было строк в исходном тексте, до применения патча (нужно для повторного рассчёта адресов новых строк)
  field :lns,        as: :lines_count, type: Integer
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
  validate :max_opened_count

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
      text_diffs: self.text_diffs,
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
        body_as_arr: [],
        tags_str: pg.tags&.join(', '),
        priority: pg.priority,
        created_at: pg.c_at,
        updated_at: pg.u_at,
      },
    }

    # когда rebase сделан, то изменения MR соответствуют тексту page, а поэтому
    # попробуем соседние строки в diff-е для удобства отрисовать во фронте
    if self.src_ver == pg.merge_ver
      h[:page][:body_as_arr] = pg.body_as_arr
    end

    h
  end

  def rebase!
    ::DiffService.new(self, self.page).rebase
  end

  def merge!
    ::DiffService.new(self, self.page).merge
  end

  def reject!
    self.update!(is_merged: 0, action_at: DateTime.now.utc.round)
  end

  def normalize_attributes
    self.u_at = DateTime.now.utc.round
  end

  def text_or_attrs_diff_must_present
    if self.attrs_diff.blank? && self.text_diffs.blank?
      self.errors.add(:id, 'Нельзя создать запрос правок, ничего не исправляя')

      if self.text_diffs.present? && self.plus_i.blank? && self.minus_i.blank?
        self.errors.add(:text_diffs, 'если есть текстовые правки, то должно быть указано их количество')
      end
    end
  end
end
