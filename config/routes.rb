Rails.application.routes.draw do
  root 'reports#index'

  get '/autocomplete', to: 'site#autocomplete'

  [:indicators, :ttps, :courses_of_action, :incidents,
  :campaigns, :threat_actors, :exploit_targets, :observables].each do |component|
    resources component do
      member do
        get :stix
      end
    end
  end

  resources :reports

  get "queries/:action" => "queries"
end
