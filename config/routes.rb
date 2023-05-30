Rails.application.routes.draw do # rubocop: disable Metrics/BlockLength
  if GalleryConfig.oauth_provider_enabled
    use_doorkeeper
  end
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
  resource :site_warning, only: %i[show create destroy], path: '/admin/warning'

  resources :resources, only: %i[destroy]

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
  end

  # Subscription page
  resources :subscriptions do
  end

  # User Preferences page
  resources :user_preferences do
  end

  # User preferences and execution environments
  resources :preferences, only: %i[index create]
  resources :environments, only: %i[index show create update destroy new edit], constraints: { id: /[^\s]+/ }

  # Notebook pages
  resources :notebooks, except: %i[new edit] do # rubocop: disable Metrics/BlockLength
    member do # rubocop: disable Metrics/BlockLength
      get 'similar'
      get 'metrics'
      get 'metrics_stars'
      get 'metrics_views'
      get 'metrics_runs'
      get 'metrics_edits'
      get 'users'
      get 'reviews'
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
      get 'feedbacks'
      post 'resource'
      get 'resources'
      patch 'resource' => 'notebooks#resource='
      post 'diff'
      get 'filter_owner'
      post 'submit_for_review'
      get 'autocomplete_notebooks'
      post 'deprecate'
      post 'remove_deprecation_status'
    end
    collection do
      get 'stars'
      get 'recommended'
      get 'recently_executed'
      get 'shared_with_me'
      get 'learning'
    end
    resources :code_cells, only: [:show]
    resources :revisions, only: %i[index show] do
      member do
        get 'download'
        get 'diff'
        get 'metadata'
        patch 'edit_friendly_label'
        patch 'edit_summary'
      end
      collection do
        get 'latest_diff'
      end
    end
  end

  # Notebook reviews
  resources :reviews, except: %i[new create edit] do
    member do
      patch 'claim'
      patch 'unclaim'
      patch 'complete'
    end
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

  # User pages
  resources :users, constraints: { id: %r{[^\/]+} } do
    member do
      get 'groups'
      get 'detail'
      get 'summary'
      get 'reviews'
    end
  end

  # Short URLs for users that don't require the id number
  # These will redirect to the full URL
  get 'u/:user_name(/:endpoint)' => 'users#short_form', constraints: { user_name: %r{[^\/]+} }
  get 'oauth/userinfo' => 'users#userinfo'

  # Admin pages
  namespace :admin do
    get 'recommender_summary'
    get 'recommender'
    get 'trendiness'
    get 'health'
    get 'user_similarity'
    get 'user_summary'
    get 'notebook_similarity'
    get 'notebooks'
    get 'packages'
    get 'exception'
    get 'download_export'
    get 'import'
    post 'import_upload'
    get 'reindex'
    patch 'group_reindex'
    patch 'notebook_reindex'
  end
  get 'admin' => 'admin#index'

  # Other pages
  root 'static_pages#home'
  get 'help' => 'static_pages#help'
  get 'home_notebooks' => 'static_pages#home_notebooks'
  get 'beta_home_notebooks' => 'static_pages#beta_home_notebooks'
  get 'beta_notebook' => 'static_pages#beta_notebook'
  get 'layout_dropdown' => 'static_pages#layout_dropdown'
  get 'faq' => 'static_pages#faq'
  get 'robots' => 'static_pages#robots'
  get 'video' => 'static_pages#video'
  get 'opensearch' => 'static_pages#opensearch'

  # XXX DEPRECATED URLs for notebooks
  get 'notebook/:id' => 'notebooks#show' # compatibility with pre-rails site
  get 'nb/:id' => 'notebooks#show'
  get 'nb/:id/:partial_title' => 'notebooks#show'
  get 'nb/:id/:partial_title/uuid' => 'notebooks#uuid'

  # XXX DEPRECATED URLs for groups
  # for backward compatibility with existing links floating around
  get 'g/:id' => 'groups#deprecated_show'
  get 'g/:id/:partial_name' => 'groups#deprecated_show'

  # Duplicate routes for dependencies files
  integration = Rails.root.join('public', 'integration')
  Dir[integration + '*dependencies.json'].each do |dep|
    file = Pathname(dep).basename.to_s
    get '/static/integration/' + file, to: static('integration/' + file)
  end

  mount Commontator::Engine => '/commontator'
end
