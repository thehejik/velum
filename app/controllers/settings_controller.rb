class SettingsController < ApplicationController
  before_action :set_setting, only: [:show, :update]

  # GET /
  def edit
  end

  # PATCH/PUT /
  def update
    # do some update calls here

    respond_to do |format|
      format.html { redirect_to settings_path, notice: 'Settings were successfully updated.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def setting_params
      params.fetch(:setting, {})
    end
end
