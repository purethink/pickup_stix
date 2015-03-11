Rails.application.routes.draw do
  root 'reports#index'

  get '/autocomplete', to: 'site#autocomplete'

  [:indicators, :ttps, :courses_of_action, :incidents,
  :campaigns, :threat_actors, :exploit_targets, :observables].each do |component|
    resources component do
      member do
        get :stix
        get :find_connections
      end
    end
  end

  resources :reports

  get "queries/:action" => "queries"

  # Auth
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post]
  match "/sign_in" => "sessions#new", :as => :signin, via: [:get]
  match "/sign_out" => "sessions#destroy", :as => :signout, via: [:get]
  get "/preferences" => "users#edit"
  get "/auth/failure", to: redirect("/sign_in?invalid=true")

  resources :users

  namespace :preferences do
    resources :bookmarks, :only => [:create, :destroy]
  end

  resources :identities
end
