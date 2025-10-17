class CreateSolarDataComplete < ActiveRecord::Migration[7.0]
  def change
    create_table :solar_data do |t|
      # Identificadores principales
      t.string :sitio
      t.string :integrador
      t.string :anio_contractual
      t.string :rpu
      t.string :mes
      t.string :periodo
      t.date :fecha

      # Costos CFE
      t.decimal :subtotal_cfe_con_sistema, precision: 12, scale: 2, default: 0
      t.decimal :pago_recibo_cfe, precision: 12, scale: 2, default: 0
      t.decimal :mensualidad_solara, precision: 12, scale: 2, default: 0
      t.decimal :subtotal_cfe_sin_sistema, precision: 12, scale: 2, default: 0

      # Generación
      t.decimal :generacion_real, precision: 12, scale: 2, default: 0
      t.decimal :generacion_garantizada, precision: 12, scale: 2, default: 0
      t.decimal :generacion_esperada, precision: 12, scale: 2, default: 0

      t.timestamps
    end

    # Índices para búsquedas rápidas
    add_index :solar_data, :sitio
    add_index :solar_data, :integrador
    add_index :solar_data, :rpu
    add_index :solar_data, :mes
    add_index :solar_data, :periodo
    add_index :solar_data, [:sitio, :rpu, :periodo], name: 'index_solar_site_rpu_period'
  end
end
