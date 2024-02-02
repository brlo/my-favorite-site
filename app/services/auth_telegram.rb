# Docs: https://core.telegram.org/widgets/login
class AuthTelegram
  attr_reader :attrs

  def initialize attrs
    # # Пример ответа от Telegram:
    # auth_date: 1665234471
    # first_name: "Rodion"
    # hash: "165c083bc88293df40d791129d24ebb7805bffb42b72af7164ac06c42560d8f6"
    # id: 252157034
    # last_name: "V"
    # photo_url: "https://t.me/i/userpic/320/MeYHzgfl6o-NvFoLNOJpwJJO82E7vYQJSZ1x0x2BWPY.jpg"
    # username: "rodion_orthodox"
    #
    # ИЛИ
    #
    # attrs = {
    #   "id"=>1048849729,
    #   "first_name"=>"Иерей Евгений",
    #   "photo_url"=>"https://t.me/i/userpic/320/zSZNgJyTbjEz1_8Rg0pnfnrWk4te81mFYOywVIiQraQ.jpg",
    #   "auth_date"=>1706881777,
    #   "hash"=>"00684d850faac9ced931f82fde84f0d2bbdff825125458682591841880fe5ee5",
    #
    #   "locale"=>"ru",
    #   "user"=>{}
    # }.symbolize_keys
    @attrs = attrs || {}
  end

  def valid?
    verified_user_data().present?
  end

  def verified_user_data
    return if attrs.blank?

    verification_hash = attrs.delete(:hash)

    # данные, из которых собираем собственный хэш (должны быть отсортированы по ключам)
    auth_data = attrs.sort_by { |k,v| k }.to_h

    # секретный токен нашего бота
    bot_token = '5733463537:AAEYqRofXdtZTXOdeuNfwixcS2db8OP_ctQ'

    # Токен бота в виде: SHA256-hash
    secret_key = OpenSSL::Digest.digest('SHA256', bot_token)
    # Наш собственный хэш из переданных параметров
    # соединяем так: "k1=v1\nk2=v2\n..." и считаем от этого HMAC-SHA256
    # HMAC-SHA-256 docs: https://docs.ruby-lang.org/en/master/OpenSSL/HMAC.html
    data_check_string = auth_data.map { |k,v| "#{k}=#{v}" }.join("\n")
    mac = OpenSSL::HMAC.hexdigest("SHA256", secret_key, data_check_string)

    if mac != verification_hash
      # данные не из Телеграма
      raise('Data is NOT from Telegram')
    end

    if (Time.now.to_i - auth_data['auth_date']) > 86400
      # старые данные (более 24h)
      raise('Data is outdated')
    end

    auth_data
  end

  def find_or_create_user!
    @user = ::User.by_telegram.where(uid: attrs[:id]).first

    new_username = attrs[:username]
    new_name = "#{attrs[:first_name]} #{attrs[:last_name]}"

    if @user.nil?
      # random password
      psw = (0...8).map { (65 + rand(26)).chr }.join
      # create user
      @user = ::User.create!(
        uid: attrs[:id],
        username: new_username,
        name: new_name,
        password: psw,
        password_confirmation: psw,
        provider: 'telegram',
      )
    else
      # если профиль изменился - актуализируем у нас в БД
      if @user.name != new_name || @user.username != new_username
        @user.update!(username: new_username, name: new_name)
      end
    end

    @user
  end
end
