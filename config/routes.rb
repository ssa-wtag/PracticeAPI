Rails.application.routes.draw do
  root 'welcome#index'
  get '/about.html' => 'welcome#about'
    use_doorkeeper  do
      #as tokens: 'log_in'
      #skip_controllers :authorizations, :applications, :authorized_applications
    end

  mount API::Dispatch => '/api'
end
