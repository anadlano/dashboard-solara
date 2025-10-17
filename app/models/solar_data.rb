class SolarData < ApplicationRecord
  self.table_name = "solar_data"

  # Validaciones
  validates :sitio, :integrador, :periodo, presence: true

  # Scopes para filtros
  scope :by_sitio, ->(sitio) { where(sitio: sitio) if sitio.present? }
  scope :by_integrador, ->(integrador) { where(integrador: integrador) if integrador.present? }
  scope :by_rpu, ->(rpu) { where(rpu: rpu) if rpu.present? }
  scope :by_mes, ->(mes) { where(mes: mes) if mes.present? }
  scope :by_periodo, ->(periodo) { where(periodo: periodo) if periodo.present? }
  scope :by_anio, ->(anio) { where(anio_contractual: anio) if anio.present? }
  scope :by_date_range, ->(start_date, end_date) {
    where(fecha: start_date..end_date) if start_date.present? && end_date.present?
  }

  # Campos disponibles para gráficas organizados por categoría
  CHART_FIELDS = {
    # Costos CFE
    'Subtotal CFE con Sistema Solar' => :subtotal_cfe_con_sistema,
    'Pago Recibo CFE' => :pago_recibo_cfe,
    'Subtotal CFE sin Sistema Solar' => :subtotal_cfe_sin_sistema,

    # Mensualidad
    'Mensualidad Solara' => :mensualidad_solara,

    # Generación
    'Generación Total' => :generacion_real,
    'Generación Garantizada' => :generacion_garantizada,
    'Generación Esperada' => :generacion_esperada,

    # Ahorros (calculados)
    'Ahorro Total' => :ahorro_total,
    'Ahorro Neto (después de mensualidad)' => :ahorro_neto
  }.freeze

  # Categorías para organizar los campos
  FIELD_CATEGORIES = {
    'CFE - Costos' => [
      :subtotal_cfe_con_sistema,
      :pago_recibo_cfe,
      :subtotal_cfe_sin_sistema
    ],
    'Mensualidad Solara' => [
      :mensualidad_solara
    ],
    'Generación (kWh)' => [
      :generacion_real,
      :generacion_garantizada,
      :generacion_esperada
    ],
    'Ahorros' => [
      :ahorro_total,
      :ahorro_neto
    ]
  }.freeze

  # Métodos calculados para ahorros
  def ahorro_total
    (subtotal_cfe_sin_sistema || 0) - (subtotal_cfe_con_sistema || 0)
  end

  def ahorro_neto
    ahorro_total - (mensualidad_solara || 0)
  end

  def porcentaje_ahorro
    return 0 if (subtotal_cfe_sin_sistema || 0).zero?
    (ahorro_total / subtotal_cfe_sin_sistema * 100).round(2)
  end

  def eficiencia_vs_garantizada
    return 0 if (generacion_garantizada || 0).zero?
    ((generacion_real || 0) / generacion_garantizada * 100).round(2)
  end

  def eficiencia_vs_esperada
    return 0 if (generacion_esperada || 0).zero?
    ((generacion_real || 0) / generacion_esperada * 100).round(2)
  end
end
