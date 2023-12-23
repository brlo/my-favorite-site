# EXAMPLES: https://github.com/cyu/rack-cors#rails-configuration
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # origins '*'
    # resource '*',
    #   headers: :any,
    #   methods: [:get, :post, :put, :patch, :delete, :options, :head]

    origins 'https://bibleox.com', 'https://edit.bibleox.com', 'http://localhost:5173'
    resource '*',
      headers: :any,
      credentials: true,
      methods: [ :get, :post, :put, :delete, :options ]
  end
end
