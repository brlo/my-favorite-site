# User.create_indexes
require 'securerandom' # for generate uuid (api_token)
require 'bcrypt' # for passwords

class User
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
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  has_secure_password

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
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
end

