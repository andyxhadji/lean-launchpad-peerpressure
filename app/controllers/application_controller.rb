class ApplicationController < ActionController::Base
  acts_as_token_authentication_handler_for User, except: [:index, :getAuthenticationToken, :api_signup]
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :name
  end
end
