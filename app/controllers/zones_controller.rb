class ZonesController < ApplicationController
  before_action :set_zone, only: [:show, :edit, :update, :destroy]

  # GET /zones
  def index
    @zones = Zone.all
  end

  # GET /zones/1
  def show
  end

  # GET /zones/new
  def new
    @zone = Zone.new
  end

  # GET /zones/1/edit
  def edit
  end

  # POST /zones
  def create
    @zone = Zone.new(zone_params)
    response = Ns1::Zone.create(zone_params[:zone])
    if response.success?
      json = JSON.parse(response.body)
      @zone.dns_servers = json['dns_servers']

      if @zone.save
        redirect_to @zone, notice: 'Zone was successfully created.'
      else
        render :new
      end
    else
      message = 'Something went wrong creating your Zone. Please try again shortly.'
      redirect_to new_zone_path, notice: message
    end
  end

  # DELETE /zones/1
  def destroy
    response = Ns1::Zone.destroy(@zone.zone)
    if response.success?
      @zone.destroy
      redirect_to zones_path, notice: 'Zone was successfully destroyed.'
    else
      message = 'Something went wrong destroying your Zone. Please try again shortly.'
      redirect_back fallback_location: zones_path, notice: message
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zone
      @zone = Zone.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def zone_params
      params.require(:zone).permit(:zone, :dns_servers)
    end
end
