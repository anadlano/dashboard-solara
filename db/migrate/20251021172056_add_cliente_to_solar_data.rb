class AddClienteToSolarData < ActiveRecord::Migration[7.1]
  def change
    add_column :solar_data, :cliente, :string
  end
end
