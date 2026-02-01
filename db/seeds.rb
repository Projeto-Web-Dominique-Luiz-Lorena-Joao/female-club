# frozen_string_literal: true

# Gerador de CPF válido
def generate_valid_cpf
  # Gera os 9 primeiros dígitos aleatórios
  cpf = Array.new(9) { rand(0..9) }

  # Calcula o primeiro dígito verificador
  sum = 0
  cpf.each_with_index { |digit, index| sum += digit * (10 - index) }
  remainder = sum % 11
  cpf << (remainder < 2 ? 0 : 11 - remainder)

  # Calcula o segundo dígito verificador
  sum = 0
  cpf.each_with_index { |digit, index| sum += digit * (11 - index) }
  remainder = sum % 11
  cpf << (remainder < 2 ? 0 : 11 - remainder)

  cpf.join
end

# Limpar dados existentes (cuidado ao executar em produção!)
puts "🧹 Limpando dados existentes..."

# Desabilitar foreign key checks temporariamente para limpeza rápida
ActiveRecord::Base.connection.execute("SET session_replication_role = 'replica';")

# Ordem de truncate respeitando dependências (tabelas dependentes primeiro)
tables_to_truncate = %w[
  stock_movements
  sale_services
  sale_products
  sales
  service_appointments
  product_outputs
  product_inputs
  products
  services
  expenses
  customers
  guarantors
  employees
  suppliers
  users
]

tables_to_truncate.each do |table|
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} CASCADE;")
end

# Reabilitar foreign key checks
ActiveRecord::Base.connection.execute("SET session_replication_role = 'origin';")

# Limpar anexos do Active Storage (fotos de funcionários e produtos)
ActiveStorage::Attachment.delete_all
ActiveStorage::Blob.delete_all

puts "✅ Dados limpos com sucesso!\n\n"

# =============================================================================
# USUÁRIOS DO SISTEMA
# =============================================================================
puts "👤 Criando usuários..."

users = [
  { name: "Administrador", email: "admin@femaleclub.com", phone: "11987654321", password: "Admin123", items_per_page: 15 },
  { name: "Gerente", email: "gerente@femaleclub.com", phone: "11987654322", password: "Gerente123", items_per_page: 20 },
  { name: "Vendedor", email: "vendedor@femaleclub.com", phone: "11987654323", password: "Vendedor123", items_per_page: 15 }
]

created_users = users.map do |user_data|
  User.create!(user_data)
end

puts "✅ #{created_users.count} usuários criados\n\n"

# =============================================================================
# FORNECEDORES
# =============================================================================
puts "🏭 Criando fornecedores..."

suppliers_data = [
  # Cosméticos
  { legal_name: "O Boticário S.A.", trade_name: "O Boticário", phone_number: "08007017070", email: "contato@boticario.com.br", full_address: "Rua Comendador Macedo, 233 - Curitiba/PR", product_category: "cosmeticos", status: "ativo" },
  { legal_name: "Natura Cosméticos S.A.", trade_name: "Natura", phone_number: "08007011125", email: "contato@natura.com.br", full_address: "Av. Alexandre Colares, 1188 - São Paulo/SP", product_category: "cosmeticos", status: "ativo" },
  { legal_name: "Avon Cosméticos Ltda.", trade_name: "Avon", phone_number: "08007021515", email: "contato@avon.com.br", full_address: "Rua Eça de Queirós, 842 - São Paulo/SP", product_category: "cosmeticos", status: "ativo" },

  # Maquiagem
  { legal_name: "Boca Rosa Beauty Ltda.", trade_name: "Boca Rosa", phone_number: "11987651234", email: "sac@bocarosa.com", full_address: "Av. Paulista, 1000 - São Paulo/SP", product_category: "maquiagem", status: "ativo" },
  { legal_name: "Ruby Rose Cosméticos", trade_name: "Ruby Rose", phone_number: "11976543210", email: "contato@rubyrose.com.br", full_address: "Rua Oscar Freire, 500 - São Paulo/SP", product_category: "maquiagem", status: "ativo" },
  { legal_name: "Vult Cosméticos S.A.", trade_name: "Vult", phone_number: "08007061234", email: "sac@vult.com.br", full_address: "Av. das Nações Unidas, 1234 - São Paulo/SP", product_category: "maquiagem", status: "ativo" },

  # Perfumaria
  { legal_name: "Marina de Bourbon", trade_name: "Marina de Bourbon", phone_number: "11912345678", email: "contato@marinadebourbon.com.br", full_address: "Shopping Iguatemi - São Paulo/SP", product_category: "perfumaria", status: "ativo" },
  { legal_name: "Eudora Cosméticos", trade_name: "Eudora", phone_number: "08007021234", email: "sac@eudora.com.br", full_address: "Rua Vergueiro, 1000 - São Paulo/SP", product_category: "perfumaria", status: "ativo" },

  # Cabelo
  { legal_name: "L'Oréal Professionnel Brasil", trade_name: "L'Oréal Professionnel", phone_number: "08007051234", email: "contato@lorealpro.com.br", full_address: "Av. Brigadeiro Faria Lima, 2000 - São Paulo/SP", product_category: "cabelo", status: "ativo" },
  { legal_name: "Kerastase Brasil Ltda.", trade_name: "Kérastase", phone_number: "08007061000", email: "sac@kerastase.com.br", full_address: "Av. Paulista, 2000 - São Paulo/SP", product_category: "cabelo", status: "ativo" },
  { legal_name: "Wella Professionals", trade_name: "Wella", phone_number: "08007071234", email: "contato@wella.com.br", full_address: "Av. das Américas, 3000 - Rio de Janeiro/RJ", product_category: "cabelo", status: "ativo" },

  # Fitness
  { legal_name: "Nike do Brasil", trade_name: "Nike", phone_number: "08008918000", email: "contato@nike.com.br", full_address: "Av. das Nações Unidas, 14401 - São Paulo/SP", product_category: "acessorios", status: "ativo" },
  { legal_name: "Adidas Brasil Ltda.", trade_name: "Adidas", phone_number: "08007071717", email: "contato@adidas.com.br", full_address: "Av. das Nações Unidas, 12995 - São Paulo/SP", product_category: "acessorios", status: "ativo" },
  { legal_name: "Puma Sports Brasil", trade_name: "Puma", phone_number: "08007071000", email: "sac@puma.com.br", full_address: "Av. Brigadeiro Faria Lima, 3000 - São Paulo/SP", product_category: "acessorios", status: "ativo" },
  { legal_name: "Fila Brasil", trade_name: "Fila", phone_number: "08007231234", email: "contato@fila.com.br", full_address: "Av. Paulista, 1500 - São Paulo/SP", product_category: "acessorios", status: "ativo" },

  # Unhas e Acessórios
  { legal_name: "Risqué Cosméticos", trade_name: "Risqué", phone_number: "08007051000", email: "sac@risque.com.br", full_address: "Rua da Consolação, 1000 - São Paulo/SP", product_category: "unhas", status: "ativo" },
  { legal_name: "Colorama Cosméticos", trade_name: "Colorama", phone_number: "08007061111", email: "contato@colorama.com.br", full_address: "Av. Rebouças, 2000 - São Paulo/SP", product_category: "unhas", status: "ativo" },

  # Equipamentos
  { legal_name: "Philco S.A.", trade_name: "Philco", phone_number: "08007071001", email: "sac@philco.com.br", full_address: "Av. Industrial, 1000 - Manaus/AM", product_category: "equipamentos", status: "ativo" }
]

suppliers = suppliers_data.map { |data| Supplier.create!(data) }
puts "✅ #{suppliers.count} fornecedores criados\n\n"

# =============================================================================
# PRODUTOS
# =============================================================================
puts "📦 Criando produtos..."

products_data = [
  # ==================== BELEZA E COSMÉTICOS ====================

  # Maquiagem - Batons
  { name: "Batom Matte Revolution", brand: "Boca Rosa Beauty", category: "beleza_cosmeticos", color: "Vermelho", sale_price: 44.85, min_stock: 15, unit: "unidade", location: "Prateleira A1", supplier: suppliers.find { |s| s.trade_name == "Boca Rosa" }, description: "Batom matte de longa duração" },
  { name: "Batom Líquido Ruby", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Rosa", sale_price: 25.90, min_stock: 20, unit: "unidade", location: "Prateleira A1", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "Batom líquido matte" },
  { name: "Batom Cremoso Diva", brand: "Vult", category: "beleza_cosmeticos", color: "Nude", sale_price: 17.94, min_stock: 25, unit: "unidade", location: "Prateleira A1", supplier: suppliers.find { |s| s.trade_name == "Vult" }, description: "Batom cremoso hidratante" },
  { name: "Batom HD Ultra Mate", brand: "Vult", category: "beleza_cosmeticos", color: "Vinho", sale_price: 21.75, min_stock: 20, unit: "unidade", location: "Prateleira A1", supplier: suppliers.find { |s| s.trade_name == "Vult" }, description: "Alta cobertura e fixação" },

  # Perfumes
  { name: "Perfume Royal Marina", brand: "Marina de Bourbon", category: "beleza_cosmeticos", color: nil, sale_price: 318.75, min_stock: 5, unit: "unidade", location: "Vitrine Principal", supplier: suppliers.find { |s| s.trade_name == "Marina de Bourbon" }, description: "Perfume feminino 100ml" },
  { name: "Colônia Lily", brand: "O Boticário", category: "beleza_cosmeticos", color: nil, sale_price: 149.90, min_stock: 10, unit: "unidade", location: "Vitrine Principal", supplier: suppliers.find { |s| s.trade_name == "O Boticário" }, description: "Colônia desodorante 100ml" },
  { name: "Perfume Kaiak Feminino", brand: "Natura", category: "beleza_cosmeticos", color: nil, sale_price: 185.75, min_stock: 8, unit: "unidade", location: "Vitrine Principal", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Eau de Toilette 100ml" },
  { name: "Perfume Far Away", brand: "Avon", category: "beleza_cosmeticos", color: nil, sale_price: 139.90, min_stock: 10, unit: "unidade", location: "Vitrine B1", supplier: suppliers.find { |s| s.trade_name == "Avon" }, description: "Eau de Parfum 50ml" },
  { name: "Perfume Siàge", brand: "Eudora", category: "beleza_cosmeticos", color: nil, sale_price: 165.50, min_stock: 8, unit: "unidade", location: "Vitrine B1", supplier: suppliers.find { |s| s.trade_name == "Eudora" }, description: "Eau de Parfum 75ml" },

  # Body Splash
  { name: "Body Splash Nativa SPA", brand: "O Boticário", category: "beleza_cosmeticos", color: nil, sale_price: 78.50, min_stock: 15, unit: "unidade", location: "Prateleira B2", supplier: suppliers.find { |s| s.trade_name == "O Boticário" }, description: "Hidratante desodorante 200ml" },
  { name: "Body Splash Tododia", brand: "Natura", category: "beleza_cosmeticos", color: nil, sale_price: 68.94, min_stock: 20, unit: "unidade", location: "Prateleira B2", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Perfumado 200ml" },

  # Blush
  { name: "Blush Compacto Rosa", brand: "Boca Rosa Beauty", category: "beleza_cosmeticos", color: "Rosa", sale_price: 41.85, min_stock: 12, unit: "unidade", location: "Prateleira A2", supplier: suppliers.find { |s| s.trade_name == "Boca Rosa" }, description: "Blush compacto alta pigmentação" },
  { name: "Blush Mosaico", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Multi", sale_price: 28.75, min_stock: 15, unit: "unidade", location: "Prateleira A2", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "Blush mosaico 4 cores" },

  # Lápis de Olho
  { name: "Lápis Kajal Preto", brand: "Vult", category: "beleza_cosmeticos", color: "Preto", sale_price: 11.94, min_stock: 30, unit: "unidade", location: "Gaveta A1", supplier: suppliers.find { |s| s.trade_name == "Vult" }, description: "Lápis kajal à prova d'água" },
  { name: "Lápis Colorido", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Azul", sale_price: 9.25, min_stock: 25, unit: "unidade", location: "Gaveta A1", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "Lápis de olho colorido" },
  { name: "Lápis Retrátil", brand: "Boca Rosa Beauty", category: "beleza_cosmeticos", color: "Marrom", sale_price: 19.90, min_stock: 20, unit: "unidade", location: "Gaveta A1", supplier: suppliers.find { |s| s.trade_name == "Boca Rosa" }, description: "Lápis retrátil de longa duração" },

  # Delineadores
  { name: "Delineador Líquido Preto", brand: "Vult", category: "beleza_cosmeticos", color: "Preto", sale_price: 23.85, min_stock: 20, unit: "unidade", location: "Gaveta A2", supplier: suppliers.find { |s| s.trade_name == "Vult" }, description: "Delineador líquido pincel fino" },
  { name: "Delineador Caneta", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Preto", sale_price: 19.90, min_stock: 25, unit: "unidade", location: "Gaveta A2", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "Delineador tipo caneta" },

  # Demaquilantes
  { name: "Água Micelar", brand: "Natura", category: "beleza_cosmeticos", color: nil, sale_price: 44.85, min_stock: 15, unit: "unidade", location: "Prateleira C1", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Água micelar 200ml" },
  { name: "Demaquilante Bifásico", brand: "O Boticário", category: "beleza_cosmeticos", color: nil, sale_price: 38.50, min_stock: 18, unit: "unidade", location: "Prateleira C1", supplier: suppliers.find { |s| s.trade_name == "O Boticário" }, description: "Remove maquiagem à prova d'água" },
  { name: "Lenço Demaquilante", brand: "Avon", category: "beleza_cosmeticos", color: nil, sale_price: 23.85, min_stock: 25, unit: "unidade", location: "Prateleira C1", supplier: suppliers.find { |s| s.trade_name == "Avon" }, description: "25 lenços demaquilantes" },

  # Shampoos Profissionais
  { name: "Shampoo Absolut Repair", brand: "L'Oréal Professionnel", category: "beleza_cosmeticos", color: nil, sale_price: 129.90, min_stock: 10, unit: "unidade", location: "Estante D1", supplier: suppliers.find { |s| s.trade_name == "L'Oréal Professionnel" }, description: "Shampoo reparador 300ml" },
  { name: "Shampoo Resistance", brand: "Kérastase", category: "beleza_cosmeticos", color: nil, sale_price: 185.75, min_stock: 8, unit: "unidade", location: "Estante D1", supplier: suppliers.find { |s| s.trade_name == "Kérastase" }, description: "Shampoo fortalecedor 250ml" },
  { name: "Shampoo Fusion", brand: "Wella", category: "beleza_cosmeticos", color: nil, sale_price: 97.75, min_stock: 12, unit: "unidade", location: "Estante D1", supplier: suppliers.find { |s| s.trade_name == "Wella" }, description: "Shampoo reconstrutor 250ml" },

  # Condicionadores Profissionais
  { name: "Condicionador Absolut Repair", brand: "L'Oréal Professionnel", category: "beleza_cosmeticos", color: nil, sale_price: 139.90, min_stock: 10, unit: "unidade", location: "Estante D2", supplier: suppliers.find { |s| s.trade_name == "L'Oréal Professionnel" }, description: "Condicionador reparador 300ml" },
  { name: "Condicionador Resistance", brand: "Kérastase", category: "beleza_cosmeticos", color: nil, sale_price: 195.50, min_stock: 8, unit: "unidade", location: "Estante D2", supplier: suppliers.find { |s| s.trade_name == "Kérastase" }, description: "Condicionador fortalecedor 200ml" },
  { name: "Condicionador Fusion", brand: "Wella", category: "beleza_cosmeticos", color: nil, sale_price: 108.94, min_stock: 12, unit: "unidade", location: "Estante D2", supplier: suppliers.find { |s| s.trade_name == "Wella" }, description: "Condicionador reconstrutor 200ml" },

  # Tintas de Cabelo
  { name: "Tinta Inoa 6.0 Louro Escuro", brand: "L'Oréal Professionnel", category: "beleza_cosmeticos", color: "Louro Escuro", sale_price: 87.85, min_stock: 10, unit: "unidade", location: "Armário E1", supplier: suppliers.find { |s| s.trade_name == "L'Oréal Professionnel" }, description: "Coloração sem amônia" },
  { name: "Tinta Koleston 7.0 Louro Médio", brand: "Wella", category: "beleza_cosmeticos", color: "Louro Médio", sale_price: 78.50, min_stock: 10, unit: "unidade", location: "Armário E1", supplier: suppliers.find { |s| s.trade_name == "Wella" }, description: "Coloração permanente" },
  { name: "Tinta Color Touch 8.0 Louro Claro", brand: "Wella", category: "beleza_cosmeticos", color: "Louro Claro", sale_price: 68.94, min_stock: 12, unit: "unidade", location: "Armário E1", supplier: suppliers.find { |s| s.trade_name == "Wella" }, description: "Tonalizante semipermanente" },

  # ==================== ACESSÓRIOS DE BELEZA ====================

  # Pentes e Escovas
  { name: "Pente de Madeira", brand: "Philco", category: "moda_acessorios", color: "Marrom", sale_price: 19.90, min_stock: 20, unit: "unidade", location: "Caixa F1", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Pente de madeira antiestático" },
  { name: "Escova Raquete", brand: "Philco", category: "moda_acessorios", color: "Preto", sale_price: 34.90, min_stock: 15, unit: "unidade", location: "Caixa F1", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Escova raquete desembaraçadora" },
  { name: "Escova Modeladora", brand: "Philco", category: "moda_acessorios", color: "Rosa", sale_price: 44.85, min_stock: 10, unit: "unidade", location: "Caixa F1", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Escova modeladora térmica" },

  # Xuxinhas
  { name: "Kit Xuxinhas Cetim", brand: "Diversos", category: "moda_acessorios", color: "Multi", sale_price: 15.90, min_stock: 30, unit: "unidade", location: "Caixa F2", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Kit com 5 xuxinhas de cetim" },
  { name: "Xuxinha Scrunchie Grande", brand: "Diversos", category: "moda_acessorios", color: "Rosa", sale_price: 8.90, min_stock: 40, unit: "unidade", location: "Caixa F2", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Xuxinha scrunchie volumosa" },

  # Presilhas
  { name: "Kit Presilhas Douradas", brand: "Diversos", category: "moda_acessorios", color: "Dourado", sale_price: 11.94, min_stock: 35, unit: "unidade", location: "Caixa F3", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Kit com 10 presilhas" },
  { name: "Presilha Tic Tac Strass", brand: "Diversos", category: "moda_acessorios", color: "Prateado", sale_price: 6.75, min_stock: 50, unit: "unidade", location: "Caixa F3", supplier: suppliers.find { |s| s.trade_name == "Philco" }, description: "Presilha decorada com strass" },

  # Unhas Postiças
  { name: "Unhas Postiças Francesinha", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Nude/Branco", sale_price: 16.90, min_stock: 25, unit: "unidade", location: "Gaveta G1", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "24 unhas postiças + cola" },
  { name: "Unhas Postiças Decoradas", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Multi", sale_price: 19.90, min_stock: 20, unit: "unidade", location: "Gaveta G1", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "24 unhas com design" },

  # Cílios Postiços
  { name: "Cílios Postiços Naturais", brand: "Vult", category: "beleza_cosmeticos", color: "Preto", sale_price: 14.90, min_stock: 30, unit: "unidade", location: "Gaveta G2", supplier: suppliers.find { |s| s.trade_name == "Vult" }, description: "Cílios efeito natural" },
  { name: "Cílios Postiços Volume", brand: "Ruby Rose", category: "beleza_cosmeticos", color: "Preto", sale_price: 11.94, min_stock: 35, unit: "unidade", location: "Gaveta G2", supplier: suppliers.find { |s| s.trade_name == "Ruby Rose" }, description: "Cílios efeito volume" },
  { name: "Cílios Postiços 3D", brand: "Boca Rosa Beauty", category: "beleza_cosmeticos", color: "Preto", sale_price: 23.85, min_stock: 20, unit: "unidade", location: "Gaveta G2", supplier: suppliers.find { |s| s.trade_name == "Boca Rosa" }, description: "Cílios 3D dramáticos" },

  # ==================== FITNESS E ESPORTES ====================

  # Leggings
  { name: "Legging Fitness Preta", brand: "Nike", category: "fitness_esportes", color: "Preto", sale_price: 185.75, min_stock: 15, unit: "unidade", location: "Araras H1", supplier: suppliers.find { |s| s.trade_name == "Nike" }, description: "Legging de compressão" },
  { name: "Legging Estampada", brand: "Adidas", category: "fitness_esportes", color: "Multi", sale_price: 175.94, min_stock: 12, unit: "unidade", location: "Araras H1", supplier: suppliers.find { |s| s.trade_name == "Adidas" }, description: "Legging com tecnologia Climalite" },
  { name: "Legging Seamless", brand: "Puma", category: "fitness_esportes", color: "Rosa", sale_price: 165.50, min_stock: 10, unit: "unidade", location: "Araras H1", supplier: suppliers.find { |s| s.trade_name == "Puma" }, description: "Legging sem costura" },

  # Tops Esportivos
  { name: "Top Esportivo Médio Impacto", brand: "Nike", category: "fitness_esportes", color: "Preto", sale_price: 129.90, min_stock: 15, unit: "unidade", location: "Araras H2", supplier: suppliers.find { |s| s.trade_name == "Nike" }, description: "Top com suporte médio" },
  { name: "Top Cropped Fitness", brand: "Adidas", category: "fitness_esportes", color: "Branco", sale_price: 97.75, min_stock: 18, unit: "unidade", location: "Araras H2", supplier: suppliers.find { |s| s.trade_name == "Adidas" }, description: "Top cropped respirável" },

  # Tênis
  { name: "Tênis Revolution 6", brand: "Nike", category: "fitness_esportes", color: "Preto/Rosa", sale_price: 345.85, min_stock: 8, unit: "pares", location: "Prateleira I1", supplier: suppliers.find { |s| s.trade_name == "Nike" }, description: "Tênis para corrida" },
  { name: "Tênis Ultraboost", brand: "Adidas", category: "fitness_esportes", color: "Branco", sale_price: 795.00, min_stock: 5, unit: "pares", location: "Prateleira I1", supplier: suppliers.find { |s| s.trade_name == "Adidas" }, description: "Tênis com tecnologia Boost" },
  { name: "Tênis Flyer Runner", brand: "Puma", category: "fitness_esportes", color: "Preto", sale_price: 275.75, min_stock: 10, unit: "pares", location: "Prateleira I1", supplier: suppliers.find { |s| s.trade_name == "Puma" }, description: "Tênis de corrida" },

  # Acessórios Fitness
  { name: "Tiara Swoosh", brand: "Nike", category: "fitness_esportes", color: "Preto", sale_price: 48.94, min_stock: 20, unit: "unidade", location: "Caixa J1", supplier: suppliers.find { |s| s.trade_name == "Nike" }, description: "Tiara esportiva antiderrapante" },
  { name: "Munhequeira Dupla", brand: "Nike", category: "fitness_esportes", color: "Branco", sale_price: 38.50, min_stock: 25, unit: "unidade", location: "Caixa J1", supplier: suppliers.find { |s| s.trade_name == "Nike" }, description: "Par de munhequeiras" },
  { name: "Luvas de Academia", brand: "Adidas", category: "fitness_esportes", color: "Preto", sale_price: 68.94, min_stock: 15, unit: "unidade", location: "Caixa J2", supplier: suppliers.find { |s| s.trade_name == "Adidas" }, description: "Luvas com proteção palmar" },
  { name: "Meias Cano Alto Kit", brand: "Nike", category: "fitness_esportes", color: "Branco", sale_price: 57.85, min_stock: 30, unit: "unidade", location: "Caixa J3", supplier: suppliers.find { |s| s.trade_name == "Nike" }, description: "Kit com 3 pares de meias" },
  { name: "Meias Invisível Kit", brand: "Adidas", category: "fitness_esportes", color: "Multi", sale_price: 48.94, min_stock: 35, unit: "unidade", location: "Caixa J3", supplier: suppliers.find { |s| s.trade_name == "Adidas" }, description: "Kit com 3 pares invisíveis" },

  # ==================== MODA E ACESSÓRIOS ====================

  # Roupas Farm
  { name: "Vestido Floral Farm", brand: "Farm", category: "moda_acessorios", color: "Multi", sale_price: 385.50, min_stock: 5, unit: "unidade", location: "Araras K1", supplier: suppliers.find { |s| s.trade_name == "O Boticário" }, description: "Vestido midi estampado" },
  { name: "Blusa Cropped Farm", brand: "Farm", category: "moda_acessorios", color: "Amarelo", sale_price: 185.75, min_stock: 8, unit: "unidade", location: "Araras K1", supplier: suppliers.find { |s| s.trade_name == "O Boticário" }, description: "Blusa cropped estampada" },

  # Roupas Animale
  { name: "Calça Pantalona Animale", brand: "Animale", category: "moda_acessorios", color: "Preto", sale_price: 595.75, min_stock: 5, unit: "unidade", location: "Araras K2", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Calça alfaiataria" },
  { name: "Blazer Estruturado Animale", brand: "Animale", category: "moda_acessorios", color: "Bege", sale_price: 895.00, min_stock: 3, unit: "unidade", location: "Araras K2", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Blazer alfaiataria" },

  # Roupas Le Lis Blanc
  { name: "Camisa Seda Le Lis", brand: "Le Lis Blanc", category: "moda_acessorios", color: "Branco", sale_price: 545.85, min_stock: 5, unit: "unidade", location: "Araras K3", supplier: suppliers.find { |s| s.trade_name == "Eudora" }, description: "Camisa de seda pura" },
  { name: "Saia Midi Le Lis", brand: "Le Lis Blanc", category: "moda_acessorios", color: "Preto", sale_price: 445.50, min_stock: 6, unit: "unidade", location: "Araras K3", supplier: suppliers.find { |s| s.trade_name == "Eudora" }, description: "Saia midi plissada" },

  # Roupas Osklen
  { name: "Vestido Linho Osklen", brand: "Osklen", category: "moda_acessorios", color: "Bege", sale_price: 785.75, min_stock: 3, unit: "unidade", location: "Araras K4", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Vestido longo linho" },

  # ==================== ESMALTES ====================
  { name: "Esmalte Cremoso Vermelho", brand: "Risqué", category: "beleza_cosmeticos", color: "Vermelho", sale_price: 6.75, min_stock: 40, unit: "unidade", location: "Expositor L1", supplier: suppliers.find { |s| s.trade_name == "Risqué" }, description: "Esmalte cremoso 8ml" },
  { name: "Esmalte Rosa Chique", brand: "Colorama", category: "beleza_cosmeticos", color: "Rosa", sale_price: 5.50, min_stock: 45, unit: "unidade", location: "Expositor L1", supplier: suppliers.find { |s| s.trade_name == "Colorama" }, description: "Esmalte cremoso 8ml" },
  { name: "Esmalte Preto Fosco", brand: "Risqué", category: "beleza_cosmeticos", color: "Preto", sale_price: 7.85, min_stock: 35, unit: "unidade", location: "Expositor L1", supplier: suppliers.find { |s| s.trade_name == "Risqué" }, description: "Esmalte acabamento fosco" },
  { name: "Esmalte Nude", brand: "Colorama", category: "beleza_cosmeticos", color: "Nude", sale_price: 5.50, min_stock: 50, unit: "unidade", location: "Expositor L1", supplier: suppliers.find { |s| s.trade_name == "Colorama" }, description: "Esmalte nude natural" },

  # ==================== HIDRATANTES E CREMES ====================
  { name: "Hidratante Corporal Ekos", brand: "Natura", category: "bem_estar_autocuidado", color: nil, sale_price: 48.94, min_stock: 20, unit: "unidade", location: "Prateleira M1", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Hidratante corporal 400ml" },
  { name: "Creme para Mãos Nativa SPA", brand: "O Boticário", category: "bem_estar_autocuidado", color: nil, sale_price: 28.75, min_stock: 25, unit: "unidade", location: "Prateleira M1", supplier: suppliers.find { |s| s.trade_name == "O Boticário" }, description: "Creme hidratante mãos 75g" },
  { name: "Hidratante Facial Chronos", brand: "Natura", category: "bem_estar_autocuidado", color: nil, sale_price: 87.85, min_stock: 15, unit: "unidade", location: "Prateleira M2", supplier: suppliers.find { |s| s.trade_name == "Natura" }, description: "Hidratante facial 40g" }
]

products = products_data.map { |data| Product.create!(data) }
puts "✅ #{products.count} produtos criados\n\n"

# =============================================================================
# SERVIÇOS
# =============================================================================
puts "💇‍♀️ Criando serviços..."

services_data = [
  { name: "Depilação Buço", description: "Depilação com cera quente da região do buço", price: 15.85, active: "ativo" },
  { name: "Depilação Perna Completa", description: "Depilação com cera de perna completa (coxa e panturrilha)", price: 62.90, active: "ativo" },
  { name: "Depilação Meia Perna", description: "Depilação com cera de meia perna (panturrilha)", price: 35.75, active: "ativo" },
  { name: "Depilação Virilha", description: "Depilação com cera da região da virilha", price: 42.50, active: "ativo" },
  { name: "Depilação Axila", description: "Depilação com cera das axilas", price: 25.90, active: "ativo" },
  { name: "Corte de Cabelo Feminino", description: "Corte de cabelo feminino com lavagem e finalização", price: 78.90, active: "ativo" },
  { name: "Corte + Escova", description: "Corte de cabelo com escova modeladora", price: 118.50, active: "ativo" },
  { name: "Colocação de Cílios Fio a Fio", description: "Extensão de cílios fio a fio", price: 155.00, active: "ativo" },
  { name: "Manutenção de Cílios", description: "Manutenção de cílios postiços", price: 82.75, active: "ativo" },
  { name: "Manicure (Mão)", description: "Cuidados com as unhas das mãos, esmaltação inclusa", price: 35.94, active: "ativo" },
  { name: "Pedicure (Pé)", description: "Cuidados com as unhas dos pés, esmaltação inclusa", price: 38.90, active: "ativo" },
  { name: "Mão e Pé", description: "Manicure e pedicure completos", price: 68.50, active: "ativo" },
  { name: "Design de Sobrancelhas", description: "Design e modelagem de sobrancelhas com pinça", price: 28.90, active: "ativo" },
  { name: "Design + Henna", description: "Design de sobrancelhas com aplicação de henna", price: 52.85, active: "ativo" },
  { name: "Micropigmentação de Sobrancelhas", description: "Micropigmentação fio a fio de sobrancelhas", price: 795.00, active: "ativo" },
  { name: "Retoque Micropigmentação", description: "Retoque de micropigmentação (após 30 dias)", price: 398.75, active: "ativo" },
  { name: "Pintura de Cabelo Global", description: "Coloração completa do cabelo", price: 175.90, active: "ativo" },
  { name: "Reflexo/Mechas", description: "Aplicação de reflexos ou mechas", price: 248.50, active: "ativo" },
  { name: "Ombré Hair", description: "Técnica de degradê no cabelo", price: 345.90, active: "ativo" },
  { name: "Escova Progressiva", description: "Tratamento alisante progressivo", price: 295.00, active: "ativo" },
  { name: "Botox Capilar", description: "Tratamento de hidratação profunda", price: 148.85, active: "ativo" },
  { name: "Hidratação Profunda", description: "Tratamento hidratante intensivo", price: 78.90, active: "ativo" },
  { name: "Penteado Social", description: "Penteado para eventos e festas", price: 115.75, active: "ativo" },
  { name: "Maquiagem Social", description: "Maquiagem para eventos", price: 145.50, active: "ativo" },
  { name: "Maquiagem Noiva", description: "Maquiagem especial para noivas", price: 298.90, active: "ativo" }
]

services = services_data.map { |data| Service.create!(data) }
puts "✅ #{services.count} serviços criados\n\n"

# =============================================================================
# FUNCIONÁRIOS (2 funcionárias)
# =============================================================================
puts "👥 Criando funcionários..."

employees_data = [
  {
    full_name: "Ana Paula Silva",
    cpf: "52998224725",
    position: "cabeleireira",
    phone: "11987654321",
    email: "ana.silva@femaleclub.com",
    address: "Rua das Flores, 123 - São Paulo/SP",
    admission_date: Date.new(2019, 1, 1),
    salary: 1500.00,
    work_days: "Segunda a Sábado",
    status: "ativo",
    notes: nil
  },
  {
    full_name: "Beatriz Costa",
    cpf: "71428793860",
    position: "manicure",
    phone: "11987654322",
    email: "beatriz.costa@femaleclub.com",
    address: "Rua dos Lírios, 456 - São Paulo/SP",
    admission_date: Date.new(2019, 1, 1),
    salary: 1500.00,
    work_days: "Segunda a Sábado",
    status: "ativo",
    notes: nil
  }
]

employees = employees_data.map { |data| Employee.create!(data) }
puts "✅ #{employees.count} funcionárias criadas\n\n"

# =============================================================================
# FIADORES
# =============================================================================
puts "🤝 Criando fiadores..."

guarantors_data = 15.times.map do |i|
  {
    full_name: ["João Silva", "Maria Santos", "José Oliveira", "Ana Costa", "Pedro Souza"].sample + " #{i}",
    cpf: generate_valid_cpf,
    phone: format("119%08d", rand(10000000..99999999)),
    address: "Rua #{['A', 'B', 'C'].sample}, #{rand(100..999)} - São Paulo/SP",
    relationship: ["pai", "mae", "irmao", "esposo", "amigo", "tio", "primo"].sample,
    status: "ativo"
  }
end

guarantors = guarantors_data.map { |data| Guarantor.create!(data) }
puts "✅ #{guarantors.count} fiadores criados\n\n"

# =============================================================================
# CLIENTES
# =============================================================================
puts "👤 Criando clientes..."

customer_names = [
  "Maria da Silva", "Ana Beatriz Costa", "Juliana Oliveira", "Fernanda Santos", "Carla Souza",
  "Patrícia Lima", "Sandra Alves", "Luciana Rodrigues", "Mônica Ferreira", "Cristina Martins",
  "Adriana Pereira", "Renata Ribeiro", "Silvia Carvalho", "Vanessa Gomes", "Cláudia Dias",
  "Regina Mendes", "Márcia Barbosa", "Rosângela Rocha", "Simone Cardoso", "Vera Araújo",
  "Eliane Fernandes", "Denise Castro", "Lúcia Moreira", "Rita Azevedo", "Solange Teixeira",
  "Célia Correia", "Marta Vieira", "Sônia Nunes", "Raquel Monteiro", "Tânia Freitas",
  "Elizabete Pinto", "Fabiana Cavalcanti", "Priscila Lopes", "Andréa Ramos", "Kátia Campos",
  "Lilian Nogueira", "Jaqueline Melo", "Viviane Duarte", "Marlene Barros", "Glória Reis",
  "Sueli Pires", "Neusa Gonçalves", "Francisca Macedo", "Aparecida Farias", "Margareth Moura",
  "Ivone Coelho", "Teresa Paiva", "Eunice Amaral", "Miriam Siqueira", "Irene Tavares"
]

customers_data = 100.times.map do |i|
  has_guarantor = [true, false, false].sample # 33% têm fiador

  {
    full_name: "#{customer_names.sample} #{i}",
    cpf: generate_valid_cpf,
    birth_date: Date.new(rand(1960..2005), rand(1..12), rand(1..28)),
    phone_number: format("119%08d", rand(10000000..99999999)),
    email: "cliente#{i}@email.com",
    full_address: "Rua #{['das Flores', 'Principal', 'Central', 'do Comércio'].sample}, #{rand(1..999)} - São Paulo/SP",
    notes: [nil, "Cliente VIP", "Prefere atendimento pela manhã", nil, nil].sample,
    guarantor: has_guarantor ? guarantors.sample : nil
  }
end

customers = customers_data.map { |data| Customer.create!(data) }
puts "✅ #{customers.count} clientes criados\n\n"

# =============================================================================
# ENTRADAS DE PRODUTOS NO ESTOQUE
# =============================================================================
puts "📥 Criando entradas de estoque..."

start_date = Date.new(2019, 1, 1)
end_date = Date.new(2026, 1, 15)

product_inputs_data = []

products.each_with_index do |product, index|
  # Definir diferentes níveis de estoque para testar os status
  # 20% dos produtos terão estoque crítico (abaixo do mínimo)
  # 20% terão estoque baixo (entre mínimo e 2x o mínimo)
  # 10% estarão fora de estoque
  # 50% terão estoque normal

  stock_level = case index % 10
                when 0, 1 then :critico      # 20% crítico
                when 2, 3 then :baixo        # 20% baixo
                when 4 then :fora_estoque    # 10% fora de estoque
                else :normal                 # 50% normal
                end

  case stock_level
  when :critico
    # Estoque crítico: quantidade <= min_stock
    # Criar poucas entradas e muitas saídas
    num_inputs = rand(2..3)
    total_entries = 0
    num_inputs.times do
      date_input = start_date + rand(0..(end_date - start_date).to_i)
      quantity = rand(5..15)  # Quantidades pequenas
      total_entries += quantity
      unit_cost = product.sale_price * rand(0.4..0.7)

      product_inputs_data << {
        product: product,
        supplier: product.supplier,
        quantity: quantity,
        unit_cost: unit_cost.round(2),
        date_input: date_input,
        invoice_number: "NF-#{rand(100000..999999)}",
        notes: "Entrada - estoque crítico",
        created_by: created_users.sample
      }
    end

  when :baixo
    # Estoque baixo: min_stock < quantidade <= min_stock * 2
    num_inputs = rand(3..5)
    num_inputs.times do
      date_input = start_date + rand(0..(end_date - start_date).to_i)
      quantity = rand(15..30)  # Quantidades moderadas
      unit_cost = product.sale_price * rand(0.4..0.7)

      product_inputs_data << {
        product: product,
        supplier: product.supplier,
        quantity: quantity,
        unit_cost: unit_cost.round(2),
        date_input: date_input,
        invoice_number: "NF-#{rand(100000..999999)}",
        notes: "Entrada - estoque baixo",
        created_by: created_users.sample
      }
    end

  when :fora_estoque
    # Fora de estoque: quantidade = 0
    # Criar apenas 1 entrada pequena no passado distante
    date_input = start_date + rand(0..365)
    quantity = rand(5..10)
    unit_cost = product.sale_price * rand(0.4..0.7)

    product_inputs_data << {
      product: product,
      supplier: product.supplier,
      quantity: quantity,
      unit_cost: unit_cost.round(2),
      date_input: date_input,
      invoice_number: "NF-#{rand(100000..999999)}",
      notes: "Entrada antiga - produto fora de estoque",
      created_by: created_users.sample
    }

  else
    # Estoque normal: quantidade > min_stock * 2
    num_inputs = rand(5..8)
    num_inputs.times do
      date_input = start_date + rand(0..(end_date - start_date).to_i)
      quantity = rand(30..100)  # Quantidades grandes
      unit_cost = product.sale_price * rand(0.4..0.7)

      product_inputs_data << {
        product: product,
        supplier: product.supplier,
        quantity: quantity,
        unit_cost: unit_cost.round(2),
        date_input: date_input,
        invoice_number: "NF-#{rand(100000..999999)}",
        notes: ["Entrada normal", "Reposição de estoque", nil, nil].sample,
        created_by: created_users.sample
      }
    end
  end
end

product_inputs = product_inputs_data.map { |data| ProductInput.create!(data) }
puts "✅ #{product_inputs.count} entradas de estoque criadas\n\n"

# =============================================================================
# SAÍDAS DE PRODUTOS DO ESTOQUE (perdas, doações, etc)
# =============================================================================
puts "📤 Criando saídas de estoque para criar diferentes níveis..."

product_outputs_data = []

products.each_with_index do |product, index|
  # Calcular quantidade disponível antes de criar saídas
  current_stock = product.product_inputs.sum(:quantity)

  next if current_stock <= 0  # Pular se não houver estoque

  # Mesma lógica do estoque para criar as saídas correspondentes
  stock_level = case index % 10
                when 0, 1 then :critico      # 20% crítico
                when 2, 3 then :baixo        # 20% baixo
                when 4 then :fora_estoque    # 10% fora de estoque
                else :normal                 # 50% normal
                end

  case stock_level
  when :critico
    # Criar saídas que deixem o produto com estoque crítico (próximo ao min_stock)
    # Deixar apenas 1-5 unidades
    target_remaining = rand(1..5)
    total_to_remove = [current_stock - target_remaining, 0].max

    if total_to_remove > 0
      num_outputs = rand(3..5)
      remaining_to_remove = total_to_remove

      num_outputs.times do |i|
        break if remaining_to_remove <= 0

        if i == num_outputs - 1
          # Última saída: remover o que sobrou
          quantity = remaining_to_remove
        else
          # Distribuir as saídas
          max_for_this = [remaining_to_remove / (num_outputs - i), 1].max
          quantity = rand(1..max_for_this)
        end

        remaining_to_remove -= quantity
        date_output = start_date + rand(0..(end_date - start_date).to_i)

        product_outputs_data << {
          product: product,
          quantity: quantity,
          output_type: ["perda", "extravio", "dano", "outro"].sample,
          date_output: date_output,
          notes: ["Produto danificado", "Perda no estoque", "Amostra grátis"].sample,
          created_by: created_users.sample
        }
      end
    end

  when :baixo
    # Deixar entre min_stock e min_stock * 2
    target_remaining = product.min_stock + rand(1..(product.min_stock))
    total_to_remove = [current_stock - target_remaining, 0].max

    if total_to_remove > 0
      num_outputs = rand(2..4)
      remaining_to_remove = total_to_remove

      num_outputs.times do |i|
        break if remaining_to_remove <= 0

        if i == num_outputs - 1
          quantity = remaining_to_remove
        else
          max_for_this = [remaining_to_remove / (num_outputs - i), 1].max
          quantity = rand(1..max_for_this)
        end

        remaining_to_remove -= quantity
        date_output = start_date + rand(0..(end_date - start_date).to_i)

        product_outputs_data << {
          product: product,
          quantity: quantity,
          output_type: ["perda", "dano", "outro"].sample,
          date_output: date_output,
          notes: ["Produto danificado", "Amostra grátis"].sample,
          created_by: created_users.sample
        }
      end
    end

  when :fora_estoque
    # Zerar o estoque
    date_output = start_date + rand(365..730)
    product_outputs_data << {
      product: product,
      quantity: current_stock,  # Remover tudo
      output_type: ["perda", "extravio"].sample,
      date_output: date_output,
      notes: "Produto esgotado - reposição necessária",
      created_by: created_users.sample
    }

  else
    # Estoque normal: remover apenas 10-30% do estoque
    if rand(1..10) > 6  # 40% dos produtos normais terão saídas pequenas
      total_to_remove = (current_stock * rand(0.1..0.3)).to_i

      if total_to_remove > 0
        num_outputs = rand(1..2)
        remaining_to_remove = total_to_remove

        num_outputs.times do |i|
          break if remaining_to_remove <= 0

          if i == num_outputs - 1
            quantity = remaining_to_remove
          else
            quantity = rand(1..remaining_to_remove)
          end

          remaining_to_remove -= quantity
          date_output = start_date + rand(0..(end_date - start_date).to_i)

          product_outputs_data << {
            product: product,
            quantity: quantity,
            output_type: ["perda", "outro"].sample,
            date_output: date_output,
            notes: ["Produto danificado", nil].sample,
            created_by: created_users.sample
          }
        end
      end
    end
  end
end

product_outputs = product_outputs_data.map { |data| ProductOutput.create!(data) }
puts "✅ #{product_outputs.count} saídas de estoque criadas\n\n"

# =============================================================================
# AGENDAMENTOS DE SERVIÇOS (apenas futuros devido à validação)
# =============================================================================
puts "📅 Criando agendamentos de serviços futuros..."

# Durações disponíveis (em minutos)
available_durations = [15, 30, 45, 60, 90, 120, 150, 180, 240]

# Horários de início disponíveis (8h às 18h)
available_hours = (8..18).to_a
available_minutes = [0, 15, 30, 45]

# Estrutura para rastrear agendamentos por funcionário e data
# Para evitar conflitos de horários
employee_schedules = {}

service_appointments_created = []

# Criar agendamentos para os próximos 30 dias
(1..30).each do |days_ahead|
  appointment_date = Date.today + days_ahead

  # Cada dia terá entre 2 e 6 agendamentos
  num_appointments_today = rand(2..6)

  num_appointments_today.times do
    employee = employees.sample
    employee_id = employee.id

    # Inicializar schedule do funcionário para este dia se não existir
    employee_schedules[employee_id] ||= {}
    employee_schedules[employee_id][appointment_date] ||= []

    # Escolher duração aleatória
    duration = available_durations.sample

    # Tentar encontrar um horário disponível (máximo 10 tentativas)
    slot_found = false
    attempts = 0

    while !slot_found && attempts < 10
      attempts += 1

      # Gerar horário aleatório
      hour = available_hours.sample
      minute = available_minutes.sample
      start_time = appointment_date.to_time.change(hour: hour, min: minute)
      end_time = start_time + duration.minutes

      # Verificar se não ultrapassa o horário de funcionamento (até 20h)
      next if end_time.hour > 20 || (end_time.hour == 20 && end_time.min > 0)

      # Verificar se há conflito com outros agendamentos do funcionário neste dia
      has_conflict = employee_schedules[employee_id][appointment_date].any? do |existing|
        existing_start = existing[:start]
        existing_end = existing[:end]

        # Verifica sobreposição de horários
        (start_time < existing_end && end_time > existing_start)
      end

      unless has_conflict
        slot_found = true

        # Registrar o slot ocupado
        employee_schedules[employee_id][appointment_date] << { start: start_time, end: end_time }

        # Criar o agendamento
        appointment = ServiceAppointment.create!(
          service: services.sample,
          employee: employee,
          customer: customers.sample,
          appointment_date: start_time,
          duration_minutes: duration,
          status: "agendado"
        )
        service_appointments_created << appointment
      end
    end
  end
end

puts "✅ #{service_appointments_created.count} agendamentos futuros criados (com horários e durações variadas)\n\n"

# =============================================================================
# VENDAS (4 a 15 vendas por dia)
# =============================================================================
puts "💰 Criando vendas (4 a 15 vendas por dia)..."
sales_data = []
now = Time.current

# Criar vendas para cada dia no período (4 a 15 vendas por dia)
(start_date..end_date).each do |date|
  num_sales_today = rand(4..15)

  num_sales_today.times do
    # 70% das vendas têm cliente cadastrado, 30% são avulsas
    customer = rand(1..10) <= 7 ? customers.sample : nil

    payment_method = ["dinheiro", "cartao_credito", "cartao_debito", "pix", "boleto"].sample
    status = payment_method == "boleto" ? ["pendente", "pago"].sample : "pago"
    due_date = payment_method == "boleto" ? date + rand(15..60) : nil
    paid_date = status == "pago" ? (due_date ? due_date - rand(0..5) : date) : nil

    discount_percentage = if customer
                           [0, 0, 0, 5, 10].sample
                         else
                           0
                         end

    notes = if customer
              ["Cliente fiel", "Cliente recorrente", nil, nil, nil].sample
            else
              "Venda avulsa"
            end

    sales_data << {
      customer_id: customer&.id,
      employee_id: employees.sample.id,
      sale_date: date,
      due_date: due_date,
      discount_percentage: discount_percentage,
      total_amount: 0,
      payment_method: payment_method,
      notes: notes,
      status: status,
      paid_date: paid_date,
      created_at: now,
      updated_at: now
    }
  end
end

# Bulk insert das vendas em lotes de 1000
puts "  Inserindo vendas em lotes..."
sales_data.each_slice(1000).with_index do |batch, index|
  Sale.insert_all(batch)
  puts "  #{(index + 1) * 1000} / #{sales_data.count} vendas inseridas..." if (index + 1) % 10 == 0
end

sales = Sale.all.to_a
puts "✅ #{sales.count} vendas criadas (4 a 15 vendas por dia)\n\n"

# =============================================================================
# ITENS DAS VENDAS (PRODUTOS E SERVIÇOS)
# =============================================================================
puts "🛍️ Adicionando produtos e serviços às vendas..."

# Preparar arrays para bulk insert
sale_products_data = []
sale_services_data = []
sale_totals = {}

# Filtrar produtos com estoque uma vez só
products_with_stock = products.select { |p| p.quantity > 0 }

sales.each do |sale|
  total = 0
  now = Time.current

  # Adicionar produtos (entre 0 e 5 produtos por venda)
  num_products = [rand(0..5), products_with_stock.count].min
  selected_products = products_with_stock.sample(num_products) if num_products > 0

  if selected_products && selected_products.any?
    selected_products.each do |product|
      available_stock = product.quantity
      next if available_stock <= 0

      quantity = [rand(1..3), available_stock].min
      unit_price = product.sale_price

      sale_products_data << {
        sale_id: sale.id,
        product_id: product.id,
        quantity: quantity,
        unit_price: unit_price,
        created_at: now,
        updated_at: now
      }

      total += quantity * unit_price
    end
  end

  # Adicionar serviços (3 a 6 serviços por venda)
  num_services = rand(3..6)
  selected_services = services.sample(num_services)

  selected_services.each do |service|
    quantity = 1
    unit_price = service.price

    sale_services_data << {
      sale_id: sale.id,
      service_id: service.id,
      quantity: quantity,
      unit_price: unit_price,
      created_at: now,
      updated_at: now
    }

    total += quantity * unit_price
  end

  # Aplicar desconto e guardar total
  discount = sale.discount_percentage / 100.0
  sale_totals[sale.id] = (total * (1 - discount)).round(2)
end

# Bulk insert de produtos e serviços
puts "  Inserindo #{sale_products_data.count} produtos vendidos..."
SaleProduct.insert_all(sale_products_data) if sale_products_data.any?

puts "  Inserindo #{sale_services_data.count} serviços vendidos..."
SaleService.insert_all(sale_services_data) if sale_services_data.any?

# Atualizar totais das vendas em lote
puts "  Atualizando totais das vendas..."
sale_totals.each_slice(1000) do |batch|
  batch.each do |sale_id, total_amount|
    Sale.where(id: sale_id).update_all(total_amount: total_amount)
  end
end

puts "✅ Produtos e serviços adicionados às vendas\n\n"

# =============================================================================
# DESPESAS
# =============================================================================
puts "💸 Criando despesas..."

expenses_data = []

# Despesas mensais fixas (Aluguel)
(start_date..end_date).select { |d| d.day == 10 }.each do |date|
  # Aluguel
  expenses_data << {
    employee: employees.first,
    supplier: nil,
    expense_date: date,
    expense_type: "aluguel",
    amount: 1200.00,
    payment_method: "transferencia",
    category: "fixa_mensal",
    notes: "Aluguel mensal do estabelecimento",
    status: "ativa"
  }

  # Utilities (Internet, Energia, Água)
  expenses_data << {
    employee: employees.first,
    supplier: nil,
    expense_date: date,
    expense_type: "utilities",
    amount: 199.90,
    payment_method: "boleto",
    category: "fixa_mensal",
    notes: "Internet fibra ótica 500MB",
    status: "ativa"
  }
end

# Despesas com fornecedores (compra de produtos)
product_inputs.sample(product_inputs.count / 2).each do |input|
  total = (input.quantity * input.unit_cost).round(2)

  expenses_data << {
    employee: employees.sample,
    supplier: input.supplier,
    expense_date: input.date_input,
    expense_type: "supplies",
    amount: total,
    payment_method: ["boleto", "transferencia", "cartao_credito"].sample,
    category: "esporadica",
    notes: "Compra de mercadorias - NF #{input.invoice_number}",
    status: "ativa"
  }
end

# Salários mensais (2 funcionárias)
(start_date..end_date).select { |d| d.day == 5 }.each do |date|
  employees.each do |employee|
    expenses_data << {
      employee: employees.first,
      supplier: nil,
      expense_date: date,
      expense_type: "salaries",
      amount: 1500.00,
      payment_method: "transferencia",
      category: "fixa_mensal",
      notes: "Salário #{employee.full_name}",
      status: "ativa"
    }
  end
end

# Outras despesas variáveis
50.times do
  date = start_date + rand(0..(end_date - start_date).to_i)
  expense_type_choice = ["utilities", "maintenance", "marketing", "other"].sample

  amount = case expense_type_choice
           when "utilities" then rand(800..2000)
           when "maintenance" then rand(300..1500)
           when "marketing" then rand(500..3000)
           when "other" then rand(100..400)
           end

  expenses_data << {
    employee: employees.sample,
    supplier: nil,
    expense_date: date,
    expense_type: expense_type_choice,
    amount: amount,
    payment_method: ["boleto", "dinheiro", "cartao_credito", "pix"].sample,
    category: "esporadica",
    notes: nil,
    status: "ativa"
  }
end

# Preparar dados para insert_all
expenses_for_insert = expenses_data.map do |data|
  {
    employee_id: data[:employee]&.id,
    supplier_id: data[:supplier]&.id,
    expense_date: data[:expense_date],
    expense_type: data[:expense_type],
    amount: data[:amount],
    payment_method: data[:payment_method],
    category: data[:category],
    notes: data[:notes],
    status: data[:status],
    created_at: Time.current,
    updated_at: Time.current
  }
end

# Bulk insert das despesas em lotes
puts "  Inserindo #{expenses_for_insert.count} despesas em lotes..."
expenses_for_insert.each_slice(1000).with_index do |batch, index|
  Expense.insert_all(batch)
  puts "  #{(index + 1) * 1000} / #{expenses_for_insert.count} despesas inseridas..." if (index + 1) % 5 == 0
end

puts "✅ #{Expense.count} despesas criadas\n\n"

# =============================================================================
# ATUALIZAR STATUS DE ESTOQUE DOS PRODUTOS
# =============================================================================
puts "📊 Atualizando status de estoque dos produtos..."

products.each do |product|
  product.update_stock_status!
end

puts "✅ Status de estoque atualizado\n\n"

# =============================================================================
# RESUMO FINAL
# =============================================================================
puts "\n" + "="*60
puts "🎉 SEEDING CONCLUÍDO COM SUCESSO! 🎉"
puts "="*60
puts "\n📊 RESUMO DOS DADOS CRIADOS:\n\n"
puts "👤 Usuários: #{User.count}"
puts "🏭 Fornecedores: #{Supplier.count}"
puts "📦 Produtos: #{Product.count}"
puts "💇‍♀️ Serviços: #{Service.count}"
puts "👥 Funcionários: #{Employee.count} (#{Employee.where("full_name LIKE '%a %' OR full_name LIKE '%na %'").count} mulheres)"
puts "🤝 Fiadores: #{Guarantor.count}"
puts "👤 Clientes: #{Customer.count}"
puts "📥 Entradas de Estoque: #{ProductInput.count}"
puts "📤 Saídas de Estoque: #{ProductOutput.count}"
puts "📅 Agendamentos: #{ServiceAppointment.count}"
puts "💰 Vendas: #{Sale.count}"
puts "   └─ Produtos Vendidos: #{SaleProduct.count}"
puts "   └─ Serviços Vendidos: #{SaleService.count}"
puts "💸 Despesas: #{Expense.count}"
puts "\n" + "="*60
puts "\n💡 Credenciais de acesso:"
puts "   Email: admin@femaleclub.com"
puts "   Senha: Admin123"
puts "\n" + "="*60
