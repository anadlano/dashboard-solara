# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_10_16_040924) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "solar_data", force: :cascade do |t|
    t.string "sitio"
    t.string "integrador"
    t.string "anio_contractual"
    t.string "rpu"
    t.string "mes"
    t.string "periodo"
    t.date "fecha"
    t.decimal "subtotal_cfe_con_sistema", precision: 12, scale: 2, default: "0.0"
    t.decimal "pago_recibo_cfe", precision: 12, scale: 2, default: "0.0"
    t.decimal "mensualidad_solara", precision: 12, scale: 2, default: "0.0"
    t.decimal "subtotal_cfe_sin_sistema", precision: 12, scale: 2, default: "0.0"
    t.decimal "generacion_real", precision: 12, scale: 2, default: "0.0"
    t.decimal "generacion_garantizada", precision: 12, scale: 2, default: "0.0"
    t.decimal "generacion_esperada", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integrador"], name: "index_solar_data_on_integrador"
    t.index ["mes"], name: "index_solar_data_on_mes"
    t.index ["periodo"], name: "index_solar_data_on_periodo"
    t.index ["rpu"], name: "index_solar_data_on_rpu"
    t.index ["sitio", "rpu", "periodo"], name: "index_solar_site_rpu_period"
    t.index ["sitio"], name: "index_solar_data_on_sitio"
  end

end
