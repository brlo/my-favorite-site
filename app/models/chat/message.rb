module Chat
  class Message < ApplicationRecord
    KINDS = %w[text system].freeze
    STATUSES = %w[pending published].freeze
    VISIBILITIES = %w[public direct].freeze

    belongs_to :room, class_name: 'Chat::Room'
    belongs_to :member, class_name: 'Chat::Member'
    belongs_to :reply_to, class_name: 'Chat::Message', optional: true
    belongs_to :recipient_member, class_name: 'Chat::Member', optional: true
    belongs_to :approved_by, class_name: 'Chat::Member', optional: true
    belongs_to :deleted_by, class_name: 'Chat::Member', optional: true
    has_many :reactions, class_name: 'Chat::Reaction', dependent: :delete_all

    validates :kind, inclusion: { in: KINDS }
    validates :status, inclusion: { in: STATUSES }
    validates :visibility, inclusion: { in: VISIBILITIES }
    validates :recipient_member, presence: true, if: -> { visibility == 'direct' }
    validates :body_html, presence: true, unless: :deleted?
    validates :lang, presence: true

    scope :alive, -> { where(deleted_at: nil) }
    scope :expired, -> { where(created_at: ...Chat::RETENTION.ago) }

    # Сообщения, которые может видеть участник:
    # - админы видят всё (кроме удалённого);
    # - остальные: опубликованные для всех + свои + адресованные лично им.
    scope :visible_to, ->(member) {
      if member&.staff?
        alive
      elsif member
        alive.where(
          "(chat_messages.status = 'published' AND chat_messages.visibility = 'public') " \
          'OR chat_messages.member_id = :id OR chat_messages.recipient_member_id = :id',
          id: member.id
        )
      else
        alive.where(status: 'published', visibility: 'public')
      end
    }

    def pending? = status == 'pending'
    def published? = status == 'published'
    def direct? = visibility == 'direct'
    def deleted? = deleted_at.present?

    # Видно всем участникам чата
    def public? = published? && visibility == 'public' && !deleted?

    def visible_to?(viewer)
      return false if deleted? || viewer.nil?
      return true if viewer.staff? || public?

      member_id == viewer.id || recipient_member_id == viewer.id
    end

    # Тело сообщения из документа TipTap (JSON). Бросает Chat::RichText::Invalid.
    def assign_body(doc, allow_links:)
      result = Chat::RichText.new(doc, allow_links: allow_links).call
      self.body_json = result.json
      self.body_html = result.html
      self.body_text = result.text
    end

    def edit_window_open?
      created_at.present? && created_at > Chat::EDIT_WINDOW.ago
    end

    def editable_by?(viewer)
      viewer.present? && !deleted? && kind == 'text' && member_id == viewer.id &&
        edit_window_open? && edits_count < Chat::MAX_EDITS && !viewer.banned?
    end

    def deletable_by?(viewer)
      viewer.present? && !deleted? && (member_id == viewer.id || viewer.staff?)
    end

    def approvable_by?(viewer)
      viewer&.staff? && pending? && !deleted?
    end

    # Ответ можно показывать с цитатой исходного сообщения, если исходное видно всем
    # или если сам ответ видят только те, кто видит и исходное (автор/адресат/админы).
    def reply_preview_visible?
      reply_to.present? && !reply_to.deleted? && (reply_to.public? || !public?)
    end

    # Редактирование. У неподтверждённых авторов одобренное сообщение
    # снова уходит на модерацию, иначе после одобрения текст можно было бы подменить.
    def apply_edit!(doc, editor:)
      assign_body(doc, allow_links: editor.staff?)
      self.edits_count += 1
      self.edited_at = Time.current
      self.translations = {}
      if !editor.verified? && published?
        self.status = 'pending'
        self.approved_at = nil
        self.approved_by = nil
      end
      save!
    end

    # Одобрить сообщение для всех. Личные ответы админов на это сообщение
    # тоже становятся видны всем. Возвращает ответы, ставшие публичными.
    def approve!(by:)
      transaction do
        update!(status: 'published', approved_by: by, approved_at: Time.current)
        Message.alive.where(reply_to_id: id, visibility: 'direct', recipient_member_id: member_id)
               .includes(:member).select { |reply| reply.member.staff? }
               .each { |reply| reply.update!(visibility: 'public', recipient_member: nil) }
      end
    end

    def soft_delete!(by:)
      update!(
        deleted_at: Time.current, deleted_by: by,
        body_json: nil, body_html: nil, body_text: nil, translations: {}
      )
      reactions.delete_all
      update_column(:reactions_summary, {})
    end

    # Перевод из кэша (только если он сделан для текущей версии текста)
    def cached_translation(lang)
      t = translations[lang.to_s]
      t['html'] if t.is_a?(Hash) && t['v'] == edits_count
    end

    # Атомарно сохранить перевод, не затирая параллельно сохранённые переводы на другие языки.
    # Если за время перевода сообщение отредактировали, перевод не сохраняется.
    def store_translation!(lang, html, version:)
      value = { 'html' => html, 'v' => version, 'at' => Time.current.iso8601 }
      Message.where(id: id, edits_count: version).update_all([
        'translations = jsonb_set(translations, ARRAY[?]::text[], ?::jsonb, true)',
        lang.to_s, value.to_json
      ])
    end

    def recount_reactions!
      summary = reactions.group(:emoji).count
      ordered = Chat::REACTIONS.each_with_object({}) { |e, h| h[e] = summary[e] if summary[e].to_i > 0 }
      update_column(:reactions_summary, ordered)
    end
  end
end
