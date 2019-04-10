Rails.application.routes.draw do
  root 'welcome#index'
    use_doorkeeper  do
      #as tokens: 'log_in'
      #skip_controllers :authorizations, :applications, :authorized_applications
    end

  mount API::Dispatch => '/api'
end
