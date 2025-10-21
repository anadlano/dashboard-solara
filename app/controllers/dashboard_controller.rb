class DashboardController < ApplicationController
  before_action :set_filter_options
  before_action :set_filtered_data

  def index
    @summary_data = calculate_summary
    @chart_data = prepare_chart_data
  end

  def sync_data
    begin
      synced_count = GoogleSheetsService.new.sync_data
      flash[:notice] = "✅ #{synced_count} registros sincronizados exitosamente desde Google Sheets"
    rescue => e
      flash[:alert] = "❌ Error: #{e.message}"
      Rails.logger.error "Error en sync_data: #{e.full_message}"
    end

    redirect_to root_path
  end

  private

  def set_filter_options
    @integradores = SolarData.distinct.pluck(:integrador).compact.sort
    @clientes = SolarData.distinct.pluck(:cliente).compact
    @sitios = SolarData.distinct.pluck(:sitio).compact.sort
    @meses = SolarData.distinct.pluck(:mes).compact.sort
    @periodos = SolarData.distinct.pluck(:periodo).compact.sort
    @anios = SolarData.distinct.pluck(:anio_contractual).compact.sort
  end

  def set_filtered_data
    @filtered_data = SolarData.all
    @filtered_data = @filtered_data.by_sitio(params[:sitio])
    @filtered_data = @filtered_data.by_integrador(params[:integrador])
    @filtered_data = @filtered_data.where(cliente: params[:cliente]) if params[:cliente].present?
    @filtered_data = @filtered_data.by_mes(params[:mes])
    @filtered_data = @filtered_data.by_periodo(params[:periodo])
    @filtered_data = @filtered_data.by_anio(params[:anio])
    @filtered_data = @filtered_data.by_date_range(params[:fecha_inicio], params[:fecha_fin])
    @filtered_data = @filtered_data.order(fecha: :asc)
  end

  def calculate_summary
    {
      total_ahorro_neto: @filtered_data.sum { |d| d.ahorro_neto },
      total_generacion_real: @filtered_data.sum(:generacion_real),
      promedio_eficiencia: calculate_average_efficiency,
      total_mensualidad: @filtered_data.sum(:mensualidad_solara),
      total_registros: @filtered_data.count,
      sitios_activos: @filtered_data.distinct.count(:sitio)
    }
  end

  def prepare_chart_data
    data = @filtered_data.order(fecha: :asc)

    {
      # Gráfica 1: Comparación CFE
      cfe_chart: {
        labels: data.map { |d| "#{d.sitio} - #{d.mes}/#{d.periodo}" },
        cfe_sin_solar: data.map { |d| (d.subtotal_cfe_sin_sistema || 0).round(2) },
        cfe_con_solar: data.map { |d| (d.subtotal_cfe_con_sistema || 0).round(2) },
        ahorro_neto: data.map { |d| d.ahorro_neto.round(2) }
      },

      # Gráfica 2: Generación y Cumplimiento
      generacion_chart: {
        labels: data.map { |d| "#{d.sitio} - #{d.mes}/#{d.periodo}" },
        generacion_real: data.map { |d| (d.generacion_real || 0).round(2) },
        generacion_garantizada: data.map { |d| (d.generacion_garantizada || 0).round(2) },
        cumplimiento: data.map { |d| d.eficiencia_vs_garantizada.round(2) }
      }
    }
  end

  def calculate_average_efficiency
    records_with_esperada = @filtered_data.where.not(generacion_esperada: [nil, 0])
    return 0 if records_with_esperada.empty?

    total_efficiency = records_with_esperada.sum { |d| d.eficiencia_vs_esperada }
    (total_efficiency / records_with_esperada.count).round(2)
  end
end
