class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  #set lists before all actions
  before_action :populate_lists
  
  helper_method :current_user, :logged_in?
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_user
    if !logged_in?
      flash[:danger] = "You must be logged in to perform that action"
      redirect_to root_path
    end
  end 
  
  def populate_lists
    @categories = Category.all.order("name ASC")
    @states = State.all.order("name ASC")
    @sources = Source.where(:active => true).order("name ASC")
    expires_in 10.days, :public => true
  end
  
  #redirect to homepage on error
  rescue_from ActionView::MissingTemplate, :with => :handle_error
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_error
  rescue_from ActiveRecord::StatementInvalid, :with => :handle_error
  rescue_from ActionController::RoutingError, :with => :handle_error

  private
  
    def handle_error
      redirect_to root_path
    end
end
