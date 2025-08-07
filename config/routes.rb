Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

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

  # default locale добавлено ради сложных ссылок link_to для админки
  scope '/:locale', :locale => /#{::R_LOCALES}/, defaults: {locale: :ru} do
    scope '/:content_lang', :content_lang => /#{::R_BIB_LANGS}/ do
      get '/:book_code/:chapter', to: 'verses#index', :constraints =>
        lambda { |req|
          book_code = req.params[:book_code]
          book = ::BOOKS[book_code]
          book && req.params[:chapter].to_i.between?(1, book[:chapters])
          # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
        },
        as: 'chapter'

      get '/chapters/:book_code/:chapter', to: 'verses#chapter_ajax', :constraints =>
        lambda { |req|
          book_code = req.params[:book_code]
          book = ::BOOKS[book_code]
          book && req.params[:chapter].to_i.between?(1, book[:chapters])
          # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
        }

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

    get '/words/:word', to: 'dict_words#word'

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

    # API
    namespace 'api', defaults: {format: :json} do

      scope 'images' do
        get  'list', to: 'images#list'
        post '/', to: 'images#create'
        put '/:id', to: 'images#update'
        delete '/:id', to: 'images#destroy'
      end

      scope 'pages' do
        get    'list', to: 'pages#list'
        post   '/',    to: 'pages#create'

        scope ':id' do
          get    '/',  to: 'pages#show'
          put    '/',  to: 'pages#update'
          delete '/',  to: 'pages#destroy'
          post   '/restore', to: 'pages#restore'
          post   '/cover', to: 'pages#cover'
          post   '/pdf', to: 'pages#add_pdf'
          delete '/pdf', to: 'pages#remove_pdf'

           # меню
          scope 'menus' do
            get    '/list', to: 'menus#list'
            post   '/',     to: 'menus#create'
            put    ':menu_item_id', to: 'menus#update'
            delete ':menu_item_id', to: 'menus#destroy'
          end
        end
      end

      scope 'merge_requests' do
        get    'list', to: 'merge_requests#list'
        post   '/',    to: 'merge_requests#create'

        scope ':id' do
          get    '/',        to: 'merge_requests#show'
          put    '/',        to: 'merge_requests#update'
          # delete '/',        to: 'merge_requests#destroy'
          post   '/merge',   to: 'merge_requests#merge'
          post   '/reject',  to: 'merge_requests#reject'
          post   '/rebase',  to: 'merge_requests#rebase'
        end
      end

      scope 'dict_words' do
        get    'list', to: 'dict_words#list'
        get    'list_waitings', to: 'dict_words#list_top_waitings'
        post   '/',    to: 'dict_words#create'

        scope ':id' do
          get    '/',        to: 'dict_words#show'
          put    '/',        to: 'dict_words#update'
          delete '/',        to: 'dict_words#destroy'
        end
      end

      scope 'stats' do
        get 'visits', to: 'stats#visits'
      end

      scope 'users' do
        get 'me', to: 'users#me'
      end

      post '/login/psw', to: 'users#psw_login'
      post '/login/telegram', to: 'users#telegram_login'
    end

    # # Admin
    # namespace 'admin' do
    #   resources :quotes_subjects
    #   resources :quotes_pages
    #   get '/dump', to: 'quotes_pages#dump', as: 'dump'
    # end

    # Defines the root path route ('/')
    get '/', to: 'verses#index'
  end

  get '/:book_code/:chapter', to: 'verses#redirect_to_new_address',
    :constraints => lambda { |req| BOOKS.key?(req.params[:book_code]) }

  root 'pages#main'
end
