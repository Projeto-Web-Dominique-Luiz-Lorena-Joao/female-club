class AddDurationMinutesToServiceAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :service_appointments, :duration_minutes, :integer, default: 60, null: false
    add_index :service_appointments, [:employee_id, :appointment_date], name: 'idx_appointments_employee_date'
  end
end
