Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  scope "/:locale", :locale => /ru|en|cs|il|gr/ do
    get '/:book_code/:chapter', to: 'verses#index', :constraints =>
      lambda { |req|
        book_code = req.params[:book_code]
        book = BOOKS[book_code]
        book && req.params[:chapter].to_i.between?(1, book[:chapters])
        # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
      }

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
    get '/q/:topic_name', to: 'quotes#show'

    # Defines the root path route ("/")
    get '/', to: 'verses#index'
  end

  get '/:book_code/:chapter', to: 'verses#redirect_to_new_address',
    :constraints => lambda { |req| BOOKS.key?(req.params[:book_code]) }

  root 'pages#main'
end
