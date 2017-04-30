Rails.application.routes.draw do # rubocop: disable Metrics/BlockLength
  devise_for :users, controllers: { sessions: 'sessions',
                                    registrations: 'registrations',
                                    confirmations: 'confirmations',
                                    passwords: 'passwords',
                                    omniauth_callbacks: 'callbacks' }

  # Group pages
  resources :groups do
    member do
      patch 'landing'
    end
  end

  # Warning/notification banner
  resource :warning, only: %i[show create destroy], path: '/admin/warning'

  # Change requests
  resources :change_requests, except: %i[new edit update] do
    member do
      get 'diff'
      get 'compare'
      get 'diff_inline'
      get 'download'
      patch 'accept'
      patch 'decline'
      patch 'cancel'
    end
    collection do
      get 'all'
    end
  end

  # Tag pages
  resources :tags, only: %i[index show] do
    collection do
      get 'wordcloud.png' => 'tags#wordcloud'
    end
  end

  # Notebook keywords
  resources :keywords, only: [:index] do
    collection do
      get 'wordcloud.png' => 'keywords#wordcloud'
    end
  end

  # User preferences and execution environments
  resources :preferences, only: %i[index create]
  resources :environments, only: %i[index show create update destroy new edit], constraints: { id: /[^\s]+/ }

  # Notebook pages
  resources :notebooks, except: %i[new edit] do # rubocop: disable Metrics/BlockLength
    member do
      get 'similar'
      get 'metrics'
      get 'metadata'
      get 'download'
      get 'shares'
      get 'uuid'
      get 'friendly_url'
      patch 'shares' => 'notebooks#shares='
      get 'star' => 'notebooks#star?'
      patch 'star' => 'notebooks#star='
      get 'public' => 'notebooks#public?'
      patch 'public' => 'notebooks#public='
      get 'owner'
      patch 'owner' => 'notebooks#owner='
      get 'title'
      patch 'title' => 'notebooks#title='
      get 'tags'
      patch 'tags' => 'notebooks#tags='
      get 'description'
      patch 'description' => 'notebooks#description='
      post 'feedback'
      get 'wordcloud.png' => 'notebooks#wordcloud'
      post 'diff'
    end
    collection do
      get 'stars'
      get 'recommended'
      get 'recently_executed'
      get 'shared_with_me'
      get 'examples'
      get 'learning'
    end
    resources :code_cells, only: [:show]
  end

  # Instrumentation
  resources :executions, only: [:create]

  # Languages
  resources :languages, only: %i[index show] do
    member do
      get '101' => 'languages#tutorial'
    end
  end

  # Staging
  resources :stages, except: %i[new edit update] do
    member do
      get 'preprocess'
    end
  end

  # Integration
  namespace :integration do
    get 'gallery_common'
    get 'gallery_tree'
    get 'gallery_notebook'
  end

  # User pages
  resources :users, constraints: { id: %r{[^\/]+} } do
    member do
      get 'groups'
      get 'detail'
    end
  end

  # Admin pages
  namespace :admin do
    get 'recommender_summary'
    get 'recommender'
    get 'trendiness'
    get 'health'
    get 'user_similarity'
    get 'notebook_similarity'
    get 'notebooks'
    get 'packages'
    get 'exception'
  end
  get 'admin' => 'admin#index'

  # Other pages
  root 'static_pages#home'
  get 'help' => 'static_pages#help'
  get 'feed' => 'static_pages#feed'
  get 'home_feed' => 'static_pages#home_feed'
  get 'home_notebooks' => 'static_pages#home_notebooks'
  get 'rss' => 'static_pages#rss'
  get 'layout_dropdown' => 'static_pages#layout_dropdown'
  get 'faq' => 'static_pages#faq'
  get 'robots' => 'static_pages#robots'
  get 'video' => 'static_pages#video'

  # Alternate URLs for notebooks
  get 'notebook/:id' => 'notebooks#show' # compatibility with pre-rails site
  get 'nb/:id' => 'notebooks#show'
  get 'nb/:id/:partial_title' => 'notebooks#show'
  get 'nb/:id/:partial_title/uuid' => 'notebooks#uuid'

  # Alternate URL for notebook metrics
  get 'nb/:id/metrics/:partial_title' => 'notebooks#metrics'

  # Alternate URLs for groups
  get 'g/:id' => 'groups#show'
  get 'g/:id/:partial_name' => 'groups#show'

  # Alternate URLs for Users
  get 'u/:id' => 'users#show', constraints: { id: %r{[^\/]+} }
  get 'u/:id/groups' => 'users#groups', constraints: { id: %r{[^\/]+} }

  # Mathjax
  mathjax 'mathjax'
end
