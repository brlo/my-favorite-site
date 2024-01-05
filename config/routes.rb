Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # default locale добавлено ради сложных ссылок link_to для админки
  scope '/:locale', :locale => /ru|gr|en|il|ar|jp|cn|de/, defaults: {locale: :ru} do
    scope '/:content_lang', :content_lang => /ru|csl-pnm|csl-ru|gr-lxx-byz|eng-nkjv|heb-osm|arab-avd|jp-ni|cn-ccbs|ge-sch/ do
      get '/:book_code/:chapter', to: 'verses#index', :constraints =>
        lambda { |req|
          book_code = req.params[:book_code]
          book = BOOKS[book_code]
          book && req.params[:chapter].to_i.between?(1, book[:chapters])
          # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
        },
        as: 'chapter'

      get '/chapters/:book_code/:chapter', to: 'verses#chapter_ajax', :constraints =>
        lambda { |req|
          book_code = req.params[:book_code]
          book = BOOKS[book_code]
          book && req.params[:chapter].to_i.between?(1, book[:chapters])
          # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
        }
    end

    scope '/:content_lang', :content_lang => /ru|gr|en|il|ar|jp|cn|de/ do
      get '/q', to: 'quotes#index'
      get '/q/:page_path', to: 'quotes#show', as: 'quote_page'
      get '/w', to: 'pages#list', as: 'pages'
      get '/w/:page_path', to: 'pages#show', as: 'page'
    end

    # СТАРАЯ АДРЕСАЦИЯ, БЕЗ УКАЗАНИЯ ЯЗЫКА КОНТЕНТА. Сейчас ловим для переадресации
    get '/:book_code/:chapter', to: 'verses#index_redirect', :constraints =>
      lambda { |req|
        book_code = req.params[:book_code]
        book = BOOKS[book_code]
        book && req.params[:chapter].to_i.between?(1, book[:chapters])
      }
    get '/q', to: 'verses#q_redirect'
    get '/q/:page_path', to: 'verses#q_redirect'

    get '/about', to: 'pages#about'
    get '/search', to: 'verses#search'

    # ищем по человеческому адресу стих и редиректим на правильный адрес
    get '/f/:human_address', :constraints => {human_address: /[\sА-ЯA-Z0-9\-\.\,\:%]+/i}, to: 'verses#goto_verse_by_human_address'

    # resources :users
    get '/profile', to: 'users#profile', as: 'profile'
    post '/profile', to: 'users#profile_update', as: 'profile_update'
    get '/login', to: 'users#login', as: 'login'
    post '/login_site', to: 'users#handle_login_site', as: 'handle_login_site'
    post '/login_telegram', to: 'users#handle_telegram_login', as: 'handle_login_telegram'
    delete '/logout', to: 'users#logout'

    # API
    namespace 'api', defaults: {format: :json} do
      post '/login/psw', to: 'users#psw_login'
      post '/login/telegram', to: 'users#telegram_login'

      scope 'pages' do
        get    'list', to: 'pages#list'
        post   '/',    to: 'pages#create'
        get    ':id',  to: 'pages#show'
        put    ':id',  to: 'pages#update'
        delete ':id',  to: 'pages#destroy'
        # меню
        scope ':id' do
          scope 'menus' do
            get    '/list', to: 'menus#list'
            post   '/',     to: 'menus#create'
            put    ':menu_item_id', to: 'menus#update'
            delete ':menu_item_id', to: 'menus#destroy'
          end
        end
      end

      scope 'quotes_subjects' do
        get    'list', to: 'quotes_subjects#list'
        post   '/',    to: 'quotes_subjects#create'
        get    ':id',  to: 'quotes_subjects#show'
        put    ':id',  to: 'quotes_subjects#update'
        delete ':id',  to: 'quotes_subjects#destroy'
      end
    end

    # Admin
    namespace 'admin' do
      resources :quotes_subjects
      resources :quotes_pages
      get '/dump', to: 'quotes_pages#dump', as: 'dump'
    end

    # Defines the root path route ('/')
    get '/', to: 'verses#index'
  end

  get '/:book_code/:chapter', to: 'verses#redirect_to_new_address',
    :constraints => lambda { |req| BOOKS.key?(req.params[:book_code]) }

  root 'pages#main'
end
