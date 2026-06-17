require 'securerandom'

class User < ApplicationRecord
  authenticates_with_sorcery!

  self.table_name = 'users'

  # username        - vasyabot
  # name            - Vasiliy Ivanovich
  # password_digest - aJHBfdsJBFDSF | blank
  # provider        - site | telegram
  # allow_ips       - ['10.0.1.3', '10.0.1.5']
  # created_at      - дата-время-создания

  has_many :pages, dependent: :nullify
  has_many :translations, dependent: :destroy
  has_many :translation_reactions, dependent: :destroy

  validates :name, length: { minimum: 2, maximum: 50 }
  validates :provider, inclusion: { in: %w[site telegram] }

  validates :username, presence: true, uniqueness: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_no_plus_subaddressing
  validate :email_domain_not_in_blacklist
  validate :email_change_too_often

  validates :password, length: { minimum: 6, maximum: 60 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  before_create :set_api_token
  before_validation :set_provider_default, on: :create
  before_validation :generate_username
  validate :uid_validation

  before_update :setup_activation, if: -> { email_changed? }
  after_update_commit :send_activation_needed_email!, if: -> { previous_changes["email"].present? }

  scope :by_site, -> { where(provider: 'site') }
  scope :by_telegram, -> { where(provider: 'telegram') }

  def get_api_token
    update!(api_token: SecureRandom.uuid) if api_token.blank?
    api_token
  end

  def allow_ip?(ip)
    # Если IP заполнены, значит пускаем только их, иначе — всех.
    allow_ips.present? ? allow_ips.include?(ip) : true
  end

  def privs_list
    _privs = privs.presence || {}
    is_admin_flag = _privs['super'] == true

    privs_names = %w[
      pages_read pages_create pages_update pages_destroy pages_self_update pages_editor_update pages_self_destroy
                              menus_update               menus_self_update

      mrs_read   mrs_create   mrs_update   mrs_destroy

      dict_read  dict_create  dict_update  dict_destroy

      gallery_read gallery_write

      super
    ]

    if is_admin_flag || is_admin
      # привилегия super открывает видимость некоторых админских полей в формах
      # но она не позволяет делать всё, что можно админу.
      # Для предоставления админских прав надо включить user.is_admin
      privs_names.index_with { true }
    else
      privs_names.select { |n| _privs[n] == true }.index_with { true }
    end
  end

  def ability?(action)
    # привелегии ещё не заданы, пользователю всё нельзя
    return false unless privs.present?
    # super может всё
    return true if privs['super'] == true || is_admin
    privs[action] == true
  end

  def can!(action)
    self.privs = {} if privs.blank?
    privs[action] = true
    save!
  end

  def cant!(action)
    return if privs.blank?
    privs.delete(action)
    save!
  end

  def max_merge_requests_count
    (privs || {})['mr_max'] || 5
  end

  # email подтверждён?
  def activated?
    activation_state == 'active'
  end

  def activation_pending?
    activation_state == 'pending'
  end

  def activation_not_started?
    activation_state.nil?
  end

  private

  def set_api_token
    self.api_token ||= SecureRandom.uuid
  end

  def set_provider_default
    self.provider ||= 'site'
  end

  def uid_validation
    if provider == 'telegram' && uid.blank?
      errors.add(:uid, 'no uid present')
    end
  end

  def email_no_plus_subaddressing
    return if email.blank?

    if email.to_s.include?('+')
      errors.add(:email, I18n.t('activerecord.errors.messages.email_cant_contain_plus'))
    end
  end

  def email_domain_not_in_blacklist
    return if email.blank?

    if ::BadEmailDomainCheckerService.disposable_email?(self.email)
      errors.add(:email, I18n.t('activerecord.errors.messages.email_in_blacklist'))
    end
  end

  def email_change_too_often
    return if ::SendUserEmailJob.new.send(:can_fire?, 'activation_needed_email', self.id)

    errors.add(:email, I18n.t('activerecord.errors.messages.email_cant_changes_too_often'))
  end

  def generate_username
    return if name.blank?
    return if username.present?

    base = name.strip.gsub(/\s+/, '_').downcase
    candidate = base
    counter = 0
    max = 100

    # Циклически проверяем, пока не найдем свободное имя
    while User.exists?(username: candidate)
      counter += 1
      break if counter > max
      candidate = "#{base}_#{counter}"
    end

    self.username = candidate
  end
end
