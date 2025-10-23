class AddAnioCalendarioToSolarData < ActiveRecord::Migration[7.1]
  def change
    add_column :solar_data, :anio_calendario, :string
  end
end
