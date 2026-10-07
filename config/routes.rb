# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  # API оффлайн-приложения (без локали в адресе)
  scope '/api/offline', module: 'api', controller: 'offline', defaults: { format: :json } do
    get 'manifest'
    get 'bible/:tr_code', action: :bible, constraints: { tr_code: /[a-z\-]+/ }
    get 'skeleton'
    get 'pages'
  end

  # Админка (без локали в адресе, интерфейс только на русском)
  namespace :admin do
    root 'dashboard#show'

    resources :pages, except: :show do
      member do
        patch :cover
        delete :cover, action: :remove_cover
        patch :pdf
        delete :pdf, action: :remove_pdf
      end
      resources :menus, only: %i[create update destroy]
    end

    resources :images, only: %i[index create update destroy]

    resources :dict_words, except: :show do
      collection do
        get :waitings
      end
    end

    resources :users, only: %i[index edit update destroy] do
      collection do
        delete :bulk_destroy
      end
      member do
        post :resend_activation
        post :activate
        post :send_password_reset
        post :unlock
        post :toggle_block
      end
    end

    get 'autocomplete/pages', to: 'autocomplete#pages', as: :autocomplete_pages
    get 'autocomplete/dict_words', to: 'autocomplete#dict_words', as: :autocomplete_dict_words
  end

  # редиректим /jp (без слеша и дополнительных частей)
  get '/:loc_ui', to: redirect(status: 301) { |params, req|
    lang = ::COUNTRY_TO_LANG[params[:loc_ui]] || 'en' # fallback на английский
    "/#{lang}"
  }, constraints: { loc_ui: /cn|gr|il|jp/ }

  # Редиректы со старых URL (коды стран) на новые (коды языков)
  # редиректим /*/ (первый элемент)
  get '/:loc_ui/*rest', to: redirect(status: 301) { |params, req|
    lang = ::COUNTRY_TO_LANG[params[:loc_ui]] || 'en' # fallback на английский
    encoded_rest = params[:rest].split('/').map { |part| ERB::Util.url_encode(part) }.join('/')
    "/#{lang}/#{encoded_rest}"
  }, constraints: { loc_ui: /cn|gr|il|jp/ }

  # Редиректы со старых URL (коды стран) на новые (коды языков)
  # редиректим /_/*/ (второй элемент)
  get '/:loc_ui/:loc_cont/*rest', to: redirect(status: 301) { |params, req|
    lang = ::COUNTRY_TO_LANG[params[:loc_cont]] || 'en' # fallback на английский
    encoded_rest = params[:rest].split('/').map { |part| ERB::Util.url_encode(part) }.join('/')
    "/#{params[:loc_ui]}/#{lang}/#{encoded_rest}"
  }, constraints: { loc_cont: /cn|gr|il|jp/ }

  # locale не задаём через defaults: дефолты маршрута перекрывают default_url_options,
  # и хелперы всегда подставляли бы :ru. Текущая локаль подставляется в ApplicationController#default_url_options.
  scope '/:locale', :locale => /#{::R_LOCALES}/ do
    # Сессии (логин/логаут)
    get 'login', to: 'sessions#new', as: :login
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy', as: :logout

    # Регистрация
    get 'signup', to: 'users#new', as: :signup
    post 'signup', to: 'users#create'

    # Профиль и остальное
    # resource :profile, only: [:show, :edit, :update]
    get '/profile', to: 'users#show', as: :profile
    resources :users do
      member do
        get :activate
        delete :block
      end
      collection do
        get :edit_main_info
        get :edit_password
        get :unlock_account
        patch :update_main_info
        patch :update_password
      end
    end
    resources :password_resets, only: %w[new create edit update]

    # Чат
    get 'chat', to: 'chat#show', as: :chat
    namespace :chat do
      resources :messages, only: %i[index show create update destroy] do
        member do
          post :approve
          post :react
          post :translate
        end
      end
      resources :members, only: %i[show update]
      resource :profile, only: %i[edit update]
      resource :room, only: :update
    end

    resources :translation_projects, path: '/translate' do
      member do
        post :import_content
        get :result
      end
      resources :segments, only: [] do
        resources :translations do
          member do
            post :upvote
            post :downvote
            patch :approve
            get :voters
            delete :remove_vote
          end
        end
      end
    end

    scope '/:content_lang', :content_lang => /#{::R_BIB_LANGS}/ do
      get '/:book_code/:chapter', to: 'verses#index', :constraints =>
        lambda { |req|
          book_code = req.params[:book_code]
          book = ::BOOKS[book_code]
          book && req.params[:chapter].to_i.between?(1, book[:chapters])
          # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
        },
        as: 'chapter'

      # Кто из святых отцов цитирует стих: фрагменты для панели справа от текста
      get '/citations/:book_code/:chapter/:line', to: 'verses#citations', :constraints =>
        lambda { |req| ::BOOKS.key?(req.params[:book_code]) }

      resources :verses, only: %w[update] do
        member do
          patch :update_interlinear_word
        end
      end

      get '/', to: 'verses#index'
    end

    scope '/:content_lang', :content_lang => /#{::R_CONT_LANGS}/ do
      # get '/w', to: 'pages#list', as: 'pages'
      get '/w/:page_path', to: 'pages#show', as: 'page'
      get '/w/:page_path/search', to: 'pages#search', as: 'page_search'
      post '/w/:page_path/search', to: 'pages#search'
      get '/w/:page_path/as_pdf', to: 'pages#page_as_pdf'

      get '/', to: 'verses#index'
    end

    # СТАРАЯ АДРЕСАЦИЯ, БЕЗ УКАЗАНИЯ ЯЗЫКА КОНТЕНТА. Сейчас ловим для переадресации
    get '/:book_code/:chapter', to: 'verses#index_redirect', :constraints =>
      lambda { |req|
        book_code = req.params[:book_code]
        book = ::BOOKS[book_code]
        book && req.params[:chapter].to_i.between?(1, book[:chapters])
      }
    get '/q', to: 'verses#q_redirect'
    get '/q/:page_path', to: 'verses#q_redirect'

    get '/words/:bib_word_id', to: 'dict_words#word'

    get '/about', to: 'pages#about'
    get '/search', to: 'verses#search'

    # ищем по человеческому адресу стих и редиректим на правильный адрес
    get '/f/:human_address', :constraints => {human_address: /[\sА-ЯA-Z0-9\-\.\,\:%]+/i}, to: 'verses#goto_verse_by_human_address'

    # # resources :users
    # get '/profile', to: 'users#profile', as: 'profile'
    # post '/profile', to: 'users#profile_update', as: 'profile_update'
    # get '/login', to: 'users#login', as: 'login'
    # post '/login_site', to: 'users#handle_login_site', as: 'handle_login_site'
    # post '/login_telegram', to: 'users#handle_telegram_login', as: 'handle_login_telegram'
    # delete '/logout', to: 'users#logout'

    get '/', to: 'verses#index'
  end

  get '/:book_code/:chapter', to: 'verses#redirect_to_new_address',
    :constraints => lambda { |req| BOOKS.key?(req.params[:book_code]) }

  root 'pages#main'
end
