class CreateServiceAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :service_appointments do |t|
      t.references :service, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.datetime :appointment_date, null: false
      t.string :status, null: false, default: 'agendado'

      t.timestamps
    end

    add_index :service_appointments, [ :service_id, :employee_id, :customer_id, :appointment_date ], name: 'idx_service_appointments_lookup'
  end
end
