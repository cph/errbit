##
# Manage problems
#
# List of actions available :
# MEMBER => :show, :edit, :update, :create, :destroy, :resolve, :unresolve, :create_issue, :unlink_issue
# COLLECTION => :index, :all, :destroy_several, :resolve_several, :unresolve_several, :merge_several, :unmerge_several, :search
class ProblemsController < ApplicationController
  include ProblemsSearcher

  before_action :need_selected_problem, only: [
    :resolve_several, :unresolve_several, :unmerge_several
  ]

  expose(:app) {
    if current_user.admin?
      App.find(params[:app_id])
    else
      current_user.apps.find(params[:app_id])
    end
  }

  expose(:err) {
    app.errs.find(params[:id])
  }

  expose(:problem) {
    err.problem if err
  }

  expose(:all_errs) {
    params[:all_errs]
  }

  expose(:app_scope) {
    apps = current_user.admin? ? App.all : current_user.apps
    params[:app_id] ? apps.where(id: params[:app_id]) : apps
  }

  expose(:params_environement) {
    params[:environment]
  }

  expose(:problems) {
    pro = Problem.for_apps(
      app_scope
    ).in_env(
      params_environement
    ).all_else_unresolved(all_errs).ordered_by(params_sort, params_order)

    if request.format == :html
      pro.page(params[:page]).per(current_user.per_page)
    else
      pro
    end
  }

  def index; end

  def show
    @notices  = problem.notices.reverse_ordered.page(params[:notice]).per(1)
    @notice   = @notices.first
    @comment = Comment.new
  end

  def create_issue
    IssueTracker.update_url_options(request)
    issue_creation = IssueCreation.new(problem, current_user, params[:tracker])

    unless issue_creation.execute
      flash[:error] = issue_creation.errors.full_messages.join(', ')
    end

    redirect_to app_err_path(app, err)
  end

  def unlink_issue
    problem.update_attribute :issue_link, nil
    redirect_to app_err_path(app, err)
  end

  def resolve
    problem.resolve!
    flash[:success] = 'Great news everyone! The err has been resolved.'
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to app_path(app)
  end

  def resolve_several
    selected_problems.each(&:resolve!)
    flash[:success] = "Great news everyone! #{I18n.t(:n_errs_have, count: selected_problems.count)} been resolved."
    redirect_to :back
  end

  def unresolve_several
    selected_problems.each(&:unresolve!)
    flash[:success] = "#{I18n.t(:n_errs_have, count: selected_problems.count)} been unresolved."
    redirect_to :back
  end

  ##
  # Action to merge several Problem in One problem
  #
  # @param [ Array<String> ] :problems the list of problem ids
  #
  def merge_several
    if selected_problems.length < 2
      flash[:notice] = I18n.t('controllers.problems.flash.need_two_errors_merge')
    else
      count = selected_problems.count
      ProblemMerge.new(selected_problems).merge
      flash[:notice] = I18n.t('controllers.problems.flash.merge_several.success', nb: count)
    end
    redirect_to :back
  end

  def unmerge_several
    all = ProblemUnmerge.execute(selected_problems)
    flash[:success] = "#{I18n.t(:n_errs_have, count: all.length)} been unmerged."
    redirect_to :back
  end

  def destroy_several
    nb_problem_destroy = ProblemDestroy.execute(selected_problems)
    flash[:notice] = "#{I18n.t(:n_errs_have, count: nb_problem_destroy)} been deleted."
    redirect_to :back
  end

  def search
    ps = Problem.search(params[:search]).for_apps(app_scope).in_env(params[:environment]).all_else_unresolved(params[:all_errs]).ordered_by(params_sort, params_order)
    selected_problems = params[:problems] || []
    self.problems = ps.page(params[:page]).per(current_user.per_page)
    respond_to do |format|
      format.html { render :index }
      format.js
    end
  end

  protected

  ##
  # Redirect :back if no errors selected
  #
  def need_selected_problem
    if err_ids.empty?
      flash[:notice] = I18n.t('controllers.problems.flash.no_select_problem')
      redirect_to :back
    end
  end
end
