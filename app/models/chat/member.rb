require 'digest'

module Chat
  class Member < ApplicationRecord
    mount_uploader :avatar, ::ChatAvatarUploader

    KINDS = %w[guest user bot].freeze
    ROLES = %w[admin moderator member guest bot].freeze
    STAFF_ROLES = %w[admin moderator].freeze

    belongs_to :user, optional: true
    has_many :messages, class_name: 'Chat::Message', dependent: :delete_all
    has_many :reactions, class_name: 'Chat::Reaction', dependent: :delete_all

    validates :kind, inclusion: { in: KINDS }
    validates :role, inclusion: { in: ROLES }
    validates :nickname, presence: true, length: { minimum: 2, maximum: 32 },
                         format: { with: /\A[\p{L}\p{N}_.\- ]+\z/ },
                         uniqueness: { case_sensitive: false }
    validates :bio, length: { maximum: 500 }
    validates :title, length: { maximum: 40 }
    validates :ui_lang, presence: true

    scope :guests, -> { where(kind: 'guest') }

    def self.digest_token(token)
      Digest::SHA256.hexdigest(token.to_s)
    end

    def self.hash_ip(ip)
      Digest::SHA256.hexdigest("#{Rails.application.secret_key_base}:#{ip}")[0, 32]
    end

    # Ник для гостя: только латиница и цифры, т.к. гости приходят из любой страны
    def self.generate_guest_nickname
      10.times do
        candidate = "Guest#{SecureRandom.random_number(10_000..999_999)}"
        return candidate unless where('lower(nickname) = ?', candidate.downcase).exists?
      end
      "Guest#{SecureRandom.hex(5)}"
    end

    # Ник для пользователя на основе его username (с подбором свободного)
    def self.generate_user_nickname(user)
      base = user.username.to_s.gsub(/[^\p{L}\p{N}_.\-]/, '')[0, 28].presence || 'User'
      base = "#{base}_" if base.length < 2
      candidate = base
      n = 0
      while where('lower(nickname) = ?', candidate.downcase).exists?
        n += 1
        candidate = "#{base}#{n}"
      end
      candidate
    end

    def guest? = kind == 'guest'
    def bot? = kind == 'bot'
    def staff? = STAFF_ROLES.include?(role) || (user&.is_admin? == true)
    def admin? = role == 'admin' || (user&.is_admin? == true)

    # Подтверждённый участник пишет сразу для всех.
    # Гость и пользователь без подтверждённой почты пишут "в скрытую" (видно только админам).
    # У пользователей из Телеграма почты нет, но их личность подтверждена Телеграмом.
    def verified?
      return true if staff? || bot?
      return false if user.nil? || user.is_blocked

      user.activated? || user.provider == 'telegram'
    end

    def banned?
      (banned_until.present? && banned_until.future?) || user&.is_blocked == true
    end

    def muted?
      muted_until.present? && muted_until.future?
    end

    # Ограничение частоты сообщений не действует на админов и ботов
    def rate_limited?
      !(staff? || bot?)
    end

    def personal_stream = "chat:member:#{id}"

    def flag
      ::FLAG_BY_LANG[ui_lang.to_s].to_s
    end
  end
end
