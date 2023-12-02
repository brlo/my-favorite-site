Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  scope '/:locale', :locale => /ru|en|cs|il|gr/, defaults: {locale: "ru"} do
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

    get '/about', to: 'pages#about'
    get '/search', to: 'verses#search'
    get '/q', to: 'quotes#index'
    get '/q/:page_path', to: 'quotes#show', as: 'quote_page'

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
    namespace 'api' do
      post '/login/psw', to: 'users#psw_login'
      post '/login/telegram', to: 'users#telegram_login'
      post '/quotes/add', to: 'quotes#add'
      delete '/quotes/del', to: 'quotes#del'
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
