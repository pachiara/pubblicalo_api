class PopulationsController < ApplicationController
  before_action :set_population, only: [:show, :edit, :update, :destroy]

  # GET /populations
  # GET /populations.json
  def index
    @populations = Population.all
  end

  # GET /populations/1
  # GET /populations/1.json
  def show
  end

  # GET /populations/new
  def new
    @population = Population.new
  end

  # GET /populations/1/edit
  def edit
  end

  # POST /populations
  # POST /populations.json
  def create
    @population = Population.new(population_params)

    respond_to do |format|
      if @population.save
        format.html { redirect_to @population, notice: 'Population was successfully created.' }
        format.json { render :show, status: :created, location: @population }
      else
        format.html { render :new }
        format.json { render json: @population.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /populations/1
  # PATCH/PUT /populations/1.json
  def update
    respond_to do |format|
      if @population.update(population_params)
        format.html { redirect_to @population, notice: 'Population was successfully updated.' }
        format.json { render :show, status: :ok, location: @population }
      else
        format.html { render :edit }
        format.json { render json: @population.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /populations/1
  # DELETE /populations/1.json
  def destroy
    @population.destroy
    respond_to do |format|
      format.html { redirect_to populations_url, notice: 'Population was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /populations.json
  # GET /populations.xml
  def v1_find
    @population = Population.search(params[:code], params[:year])
    respond_to do |format|
      format.json { render json: @population }
      format.xml  { render xml: @population }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_population
      @population = Population.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def population_params
      params.require(:population).permit(:code, :region, :year, :people)
    end
end
