# frozen_string_literal: true

# Cria apenas o usuário administrador padrão
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@femaleclub.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "Admin123!")

if User.find_by(email: admin_email).nil?
  User.create!(
    email: admin_email,
    password: admin_password,
    password_confirmation: admin_password,
    admin: true
  )
  puts "=> Usuário admin criado: #{admin_email}"
else
  puts "=> Usuário admin já existe."
end
