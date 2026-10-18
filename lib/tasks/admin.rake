namespace :admin do
  desc "Cria o usuário administrador inicial a partir de ADMIN_EMAIL e ADMIN_PASSWORD"
  task create: :environment do
    email = ENV["ADMIN_EMAIL"]
    senha = ENV["ADMIN_PASSWORD"]

    if email.blank? || senha.blank?
      puts "[admin:create] ADMIN_EMAIL/ADMIN_PASSWORD não definidos — pulando."
      next
    end

    user = User.find_or_initialize_by(email: email.downcase.strip)

    if user.persisted?
      puts "[admin:create] Usuário #{user.email} já existe — nada a fazer."
      next
    end

    user.name = ENV.fetch("ADMIN_NAME", "Administrador")
    user.password = senha
    user.password_confirmation = senha
    user.admin = true
    user.active = true

    if user.save
      puts "[admin:create] Administrador #{user.email} criado com sucesso."
    else
      puts "[admin:create] ERRO ao criar administrador: #{user.errors.full_messages.join(', ')}"
    end
  end
end