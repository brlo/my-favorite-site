# User.create_indexes
require 'securerandom' # for generate uuid (api_token)
require 'bcrypt' # for passwords

class User < ApplicationMongoRecord
  include Mongoid::Document
  include ActiveModel::SecurePassword

  # username        - vasyabot
  # name            - Vasiliy Ivanovich
  # password_digest - aJHBfdsJBFDSF | blank
  # provider        - site | telegram
  # allow_ips       - ['10.0.1.3', '10.0.1.5']
  # created_at      - дата-время-создания

  field :username, type: String
  field :name, type: String
  field :password_digest, type: String
  field :provider, type: String # telegram
  field :uid, type: String
  field :api_token, type: String
  field :allow_ips, type: Array
  field :is_admin, type: Boolean
  field :privs, type: Hash
  field :pages_owner, type: Array
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  has_secure_password

  has_many :pages, foreign_key: 'u_id', primary_key: 'id'
  has_many :merge_requests, foreign_key: 'u_id', primary_key: 'id'

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # User.remove_undefined_indexes
  # User.remove_indexes
  # User.create_indexes
  index({api_token: 1},             {unique: true, background: true})
  index({username: 1},              {unique: true, background: true})
  index({username: 1, provider: 1},               {background: true})

  scope :by_site,      -> { where(provider: 'site') }
  scope :by_telegram,  -> { where(provider: 'telegram') }

  validates :username, presence: true
  validates :provider, inclusion: {in: %w(site telegram)}

  validate :password_digest_validation
  validate :uid_validation

  def password_digest_validation
    if provider == 'site' && password_digest.blank?
      errors.add(
        :password_digest,
        :blank,
        message: 'no password present'
      )
    end
  end

  def get_api_token
    if self.api_token.blank?
      self.update!(api_token: ::SecureRandom.uuid)
    end

    self.api_token
  end

  def uid_validation
    if provider == 'telegram' && uid.blank?
      errors.add(
        :uid,
        :blank,
        message: 'no uid present'
      )
    end
  end

  def allow_ip?(ip)
    # Если IP заполнены, значит пускаем только их, иначе — всех.
    if self.allow_ips.present?
      self.allow_ips.include?(ip)
    else
      true
    end
  end

  def privs_list
    _privs = self.privs.presence || {}
    is_admin = _privs['super'] == true

    privs_names = %w(
      pages_read pages_create pages_update pages_destroy pages_self_update pages_editor_update pages_self_destroy
                              menus_update               menus_self_update
      mr_read    mr_create    mr_update    mr_destroy
      dict_read  dict_create  dict_update  dict_destroy

      super
    )
    if is_admin
      # привилегия super открывает видимость некоторых админских полей в формах
      # но она не позволяет делать всё, что можно админу.
      # Для предоставления админских прав надо включить user.is_admin
      privs_names.map { |n| [n, true] }.to_h
    else
      can_names = privs_names.select { |n| _privs[n] == true }
      can_names.map { |n| [n, true] }.to_h
    end
  end

  # pages_read
  # pages_create
  # pages_update
  # pages_destroy
  # pages_self_update - обновлять свои статьи
  # pages_editor_update - обновлять статьи, где я редактор (принят хоть один MR)
  # pages_self_destroy - удалять свои статьи
  #
  # mrs_read
  # mrs_create
  # mrs_update
  # mrs_destroy
  # mrs_merge - даёт парво на merge, rebase
  # mrs_reject
  # mrs_self_reject
  #
  # dict_read
  # dict_create
  # dict_update
  # dict_destroy
  #
  # mr_max
  #
  def ability?(action)
    _privs = self.privs

    # привелегии ещё не заданы, пользователю всё нельзя
    return false unless _privs.present?

    # super может всё
    return true if _privs['super'] == true

    _privs[action] == true
  end

  def can!(action)
    self.privs = {} if self.privs.blank?
    self.privs[action] = true
    self.save!
  end

  def cant!(action)
    return if self.privs.blank?
    self.privs.delete(action)
    self.save!
  end

  def max_merge_requests_count
    default = 5
    (self.privs || {})['mr_max'] || default
  end
end

