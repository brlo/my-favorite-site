Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # quote
  get '/:book_code/:chapter', to: 'verses#index', :constraints =>
    lambda { |req|
      book_code = req.params[:book_code]
      book = BOOKS[book_code]
      book && req.params[:chapter].to_i.between?(1, book[:chapters])
      # :link => /[0-9a-z]{2,5}\:[0-9]{1,3}/
    }

  get 'about', to: 'pages#about'
  get 'search', to: 'verses#search'
  get 'q', to: 'quotes#index'

  # Defines the root path route ("/")
  root "verses#index"
end
