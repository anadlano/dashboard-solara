require 'google/apis/sheets_v4'
require 'googleauth'

class GoogleSheetsService
  SPREADSHEET_ID = ENV['GOOGLE_SPREADSHEET_ID']
  SHEET_NAME = 'conglomerado_automatizado' # ← Nombre de tu pestaña
  RANGE = "#{SHEET_NAME}!A1:N" # Ajusta según el número de columnas

  def initialize
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = authorize
  end

  def fetch_data
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, RANGE)
    response.values || []
  rescue => e
    Rails.logger.error "Error al obtener datos de Google Sheets: #{e.message}"
    []
  end

  def fetch_headers
    response = @service.get_spreadsheet_values(SPREADSHEET_ID, "#{SHEET_NAME}!A1:M1")
    response.values.first || []
  rescue => e
    Rails.logger.error "Error al obtener headers: #{e.message}"
    []
  end

  def sync_data
    rows = fetch_data
    return 0 if rows.empty?

    headers = rows.first
    synced_count = 0
    errors = []

    Rails.logger.info "📋 Headers encontrados: #{headers.inspect}"

    rows[1..-1].each_with_index do |row, index|
      next if row.size < 5 # Al menos necesitamos los campos básicos

      begin
        data_hash = headers.zip(row).to_h

        # Log para debugging
        Rails.logger.info "Procesando fila #{index + 2}: #{data_hash.inspect}"

        solar_data = SolarData.find_or_initialize_by(
          sitio: data_hash['sitio'],
          rpu: data_hash['RPU'],
          periodo: data_hash['Periodo']
        )

        solar_data.assign_attributes(
          integrador: data_hash['Integrador'],
          anio_contractual: data_hash['Año contractual'],
          mes: data_hash['Mes'],
          fecha: parse_date_from_periodo(data_hash['Periodo']),
          cliente: data_hash['Cliente'],

          # Costos CFE
          subtotal_cfe_con_sistema: parse_decimal(data_hash['Subtotal CFE con Sistema Solar']),
          pago_recibo_cfe: parse_decimal(data_hash['Pago recibo CFE']),
          mensualidad_solara: parse_decimal(data_hash['Mensualidad Solara']),
          subtotal_cfe_sin_sistema: parse_decimal(data_hash['Subtotal CFE sin Sistema Solar *']),

          # Generación
          generacion_real: parse_decimal(data_hash['Generación total']),
          generacion_garantizada: parse_decimal(data_hash['Generación garantizada']),
          generacion_esperada: parse_decimal(data_hash['Generación esperada'])
        )

        if solar_data.save
          synced_count += 1
        else
          errors << "Fila #{index + 2}: #{solar_data.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Fila #{index + 2}: #{e.message}"
        Rails.logger.error "Error en fila #{index + 2}: #{e.full_message}"
      end
    end

    Rails.logger.info "✅ Sincronización completada: #{synced_count} registros"
    Rails.logger.error "❌ Errores: #{errors.join(' | ')}" if errors.any?

    synced_count
  end

  private

  def authorize
    # Usar variable de ambiente en producción, archivo local en desarrollo
    credentials = if ENV['GOOGLE_CREDENTIALS_JSON'].present?
      # Producción: cargar desde variable de ambiente
      StringIO.new(ENV['GOOGLE_CREDENTIALS_JSON'])
    else
      # Desarrollo: cargar desde archivo local
      credentials_path = Rails.root.join('config', 'google_credentials', 'service_account.json')

      unless File.exist?(credentials_path)
        raise "Error: No se encontró el archivo de credenciales en: #{credentials_path}"
      end

      File.open(credentials_path)
    end

    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: credentials,
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
    )
  end

  def parse_date_from_periodo(periodo)
    return Date.current if periodo.blank?

    # Si el periodo está en formato YYYYMM (202410)
    if periodo.to_s.match?(/^\d{6}$/)
      year = periodo.to_s[0..3].to_i
      month = periodo.to_s[4..5].to_i
      Date.new(year, month, 1)
    else
      Date.current
    end
  rescue
    Date.current
  end

  def parse_date(date_string)
    return Date.current if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError
    Date.current
  end

  def parse_decimal(value)
    return 0.0 if value.blank?
    # Remover símbolos de moneda, comas, porcentajes
    cleaned = value.to_s.gsub(/[$,MXN%\s]/, '').strip
    cleaned.empty? ? 0.0 : cleaned.to_f
  end
end
