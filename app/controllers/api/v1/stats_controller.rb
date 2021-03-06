class Api::V1::StatsController < ApplicationController
  respond_to :json, :xml

  # The stats API only requires an api_key for the given app.
  skip_before_action :authenticate_user!
  before_action :require_api_key_or_authenticate_user!

  def app
    if problem = @app.problems.order("last_notice_at desc").first
      @last_error_time = problem.last_notice_at
    end

    stats = {
      name: @app.name,
      last_error_time: @last_error_time,
      unresolved_errors: @app.unresolved_count
    }

    respond_to do |format|
      format.html { render json: MultiJson.dump(stats) } # render JSON if no extension specified on path
      format.json { render json: MultiJson.dump(stats) }
      format.xml  { render xml:  stats }
    end
  end


  protected

  def require_api_key_or_authenticate_user!
    if params[:api_key].present?
      if @app = App.where(api_key: params[:api_key]).first
        return true
      end
    end

    authenticate_user!
  end

end


