class FinancialPlansController < ApplicationController
  before_action :set_financial_plan, only: [:show]

  # GET /financial_plans.json
  # GET /financial_plans.xml
  def v1_all
    @financial_plans = FinancialPlan.all
    respond_to do |format|
      format.json { render json: @financial_plans }
      format.xml  { render xml: @financial_plans }
    end
  end

  # GET /financial_plans.json
  # GET /financial_plans.xml
  def v1_find
    # paginazione
    if params[:page].nil? && !session[:page].nil?
      params[:page] = session[:page]
    end
    if params[:per_page].nil? && !session[:per_page].nil?
      params[:per_page] = session[:per_page]
    end
    # default 20 righe per pagina
    if params[:per_page].nil? || params[:per_page].to_s.strip.length == 0
      params[:per_page] = 20
    end
    # ricerca
    @financial_plans = FinancialPlan.search(params[:mandante], params[:societa], params[:anno], params[:tipo_conto], params[:livello], params[:conto], params[:voce], params[:ricerca], params[:sort_column], params[:sort_order], params[:page], params[:per_page])

    # salva valori in sessione
    session[:page] = params[:page]
    session[:per_page] = params[:per_page]

    respond_to do |format|
      format.json { render json: @financial_plans }
      format.xml  { render xml: @financial_plans }
    end
  end

  # GET /financial_plans.json
  # GET /financial_plans.xml
  def v1_simple_find
    # paginazione
    if params[:page].nil? && !session[:page].nil?
      params[:page] = session[:page]
    end
    if params[:per_page].nil? && !session[:per_page].nil?
      params[:per_page] = session[:per_page]
    end
    # default 20 righe per pagina
    if params[:per_page].nil? || params[:per_page].to_s.strip.length == 0
      params[:per_page] = 20
    end
    # ricerca
    @financial_plans = FinancialPlan.simple_search(params[:mandante], params[:societa], params[:anno], params[:tipo_conto], params[:livello], params[:conto], params[:voce], params[:ricerca], params[:sort_column], params[:sort_order], params[:page], params[:per_page])

    # salva valori in sessione
    session[:page] = params[:page]
    session[:per_page] = params[:per_page]

    respond_to do |format|
      format.json { render json: @financial_plans }
      format.xml  { render xml: @financial_plans }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_financial_plan
      @financial_plan = FinancialPlan.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def financial_plan_params
      params[:financial_plan]
    end
end
