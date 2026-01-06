require 'securerandom'
require 'bcrypt'

class User < ApplicationRecord
  self.table_name = 'users'

  has_secure_password

  # username        - vasyabot
  # name            - Vasiliy Ivanovich
  # password_digest - aJHBfdsJBFDSF | blank
  # provider        - site | telegram
  # allow_ips       - ['10.0.1.3', '10.0.1.5']
  # created_at      - дата-время-создания

  has_many :pages, dependent: :nullify
  has_many :merge_requests, dependent: :nullify

  validates :username, presence: true
  validates :provider, inclusion: { in: %w[site telegram] }

  validate :password_digest_validation
  validate :uid_validation

  before_create :set_api_token
  before_validation :set_provider_default, on: :create

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

  private

  def set_api_token
    self.api_token ||= SecureRandom.uuid
  end

  def set_provider_default
    self.provider ||= 'site'
  end

  def password_digest_validation
    if provider == 'site' && password_digest.blank?
      errors.add(:password_digest, 'no password present')
    end
  end

  def uid_validation
    if provider == 'telegram' && uid.blank?
      errors.add(:uid, 'no uid present')
    end
  end
end
