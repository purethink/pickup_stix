Rails.application.routes.draw do
  root 'reports#index'

  get '/autocomplete', to: 'site#autocomplete'

  [:indicators, :ttps, :courses_of_action, :incidents,
   :campaigns, :threat_actors, :exploit_targets, :observables].each do |component|
     resources component
   end

   resources :reports
end
