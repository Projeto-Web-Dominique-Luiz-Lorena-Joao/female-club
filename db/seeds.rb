# Clear all existing data
puts "Deletando registros existentes..."
ProductOutput.delete_all
ProductInput.delete_all
StockMovement.delete_all
SaleService.delete_all
SaleProduct.delete_all
Sale.delete_all
ServiceAppointment.delete_all if defined?(ServiceAppointment)
Service.delete_all
Product.delete_all
Expense.delete_all if defined?(Expense)
Supplier.delete_all
Customer.delete_all
Employee.delete_all
User.delete_all
Guarantor.delete_all if defined?(Guarantor)

puts "✓ Todos os registros foram deletados"

# Seed Users
puts "\nCriando 30 usuários..."
users = []
30.times do |i|
  user = User.create!(
    email: "user#{i + 1}@example.com",
    password: "password123",
    password_confirmation: "password123",
    name: "Usuário #{i + 1}"
  )
  users << user
end
puts "✓ #{users.count} usuários criados"

# Seed Employees with real Brazilian names
puts "\nCriando 30 funcionários..."
employees = []
employee_names = [
  "Ana Silva", "Bruno Santos", "Carla Oliveira", "Diego Martins", "Eliana Costa",
  "Fernando Pereira", "Gabriela Alves", "Henrique Rocha", "Isabela Gomes", "João Ferreira",
  "Kátia Mendes", "Lucas Ribeiro", "Mariana Sousa", "Nicolas Dias", "Otávio Araujo",
  "Patrícia Campos", "Quentin Lourenço", "Roberta Andrade", "Samuel Barbosa", "Tatiana Lopes",
  "Ulisses Castro", "Vanessa Tavares", "Wagner Nunes", "Ximena Saraiva", "Yasmin Freitas",
  "Zilda Monteiro", "Amanda Barros", "Breno Oliveira", "Cintia Machado", "Danilo Serrano"
]

employee_names.each_with_index do |name, i|
  cpf = rand(10000000..99999999).to_s + rand(100..999).to_s
  employee = Employee.create!(
    full_name: name,
    cpf: cpf,
    email: "employee#{i + 1}@example.com",
    phone: "#{11}99#{rand(100000..999999)}",
    status: [ 'ativo', 'inativo', 'ferias', 'afastado' ].sample,
    position: [ 'vendedor', 'gerente', 'caixa', 'estoquista' ].sample
  )
  employees << employee
end
puts "✓ #{employees.count} funcionários criados"

# Seed Customers with real Brazilian names
puts "\nCriando 30 clientes..."
customers = []
customer_names = [
  "Marta Gomes", "Rita Pereira", "Simone Ribeiro", "Tânia Ferreira", "Úrsula Mendes",
  "Vanessa Rocha", "Wanda Alves", "Ximena Coelho", "Yasmin Araújo", "Zélia Cardoso",
  "Adriana Lopes", "Beatriz Campos", "Cláudia Nunes", "Dorothea Barros", "Estela Teixeira",
  "Francisca Monteiro", "Geraldina Costa", "Helena Souza", "Irene Barbosa", "Joana Machado",
  "Kamila Santos", "Leticia Tavares", "Miriam Oliveira", "Natalia Castillo", "Olga Dias",
  "Priscila Lourenço", "Quésia Serrano", "Rosário Andrade", "Sandra Saraiva", "Theodora Freitas"
]

customer_names.each_with_index do |name, i|
  customer = Customer.create!(
    full_name: name,
    email: "customer#{i + 1}@example.com",
    phone_number: "#{11}98#{rand(100000..999999)}",
    full_address: "Rua #{name.split.last}, Número #{rand(1..999)}, Bairro #{ [ 'Centro', 'Vila', 'Zona', 'Parque' ].sample }"
  )
  customers << customer
end
puts "✓ #{customers.count} clientes criados"

# Seed Guarantors with real Brazilian names and associate with customers
puts "\nCriando 30 fiadores..."
guarantor_names = [
  "Paulo Gomes", "Rodrigo Pereira", "Sergio Ribeiro", "Thiago Ferreira", "Ulisses Mendes",
  "Victor Rocha", "Wagner Alves", "Xavier Coelho", "Yuri Araújo", "Zeferino Cardoso",
  "Alberto Lopes", "Benedito Campos", "Cesário Nunes", "Davino Barros", "Evaristo Teixeira",
  "Fabiano Monteiro", "Germano Costa", "Hildebrando Souza", "Isidoro Barbosa", "Jacinto Machado",
  "Kaique Santos", "Lourenço Tavares", "Marcial Oliveira", "Narciso Castillo", "Odair Dias",
  "Perseu Lourenço", "Quincas Serrano", "Ramiro Andrade", "Sérgio Saraiva", "Tertuliano Freitas"
]

guarantors = []
guarantor_names.each_with_index do |name, i|
  guarantor = Guarantor.create!(
    full_name: name,
    cpf: rand(10000000..99999999).to_s + rand(100..999).to_s
  )
  guarantors << guarantor
end

# Assign guarantors to some customers
customers.each_with_index do |customer, index|
  if index % 2 == 0 && guarantors[index].present?
    customer.update(guarantor: guarantors[index])
  end
end

puts "✓ #{guarantors.count} fiadores criados"

# Seed Suppliers
puts "\nCriando 30 fornecedores..."
suppliers = []
30.times do |i|
  supplier = Supplier.create!(
    legal_name: "Fornecedor #{i + 1}",
    trade_name: "Fornecedor #{i + 1} - Comércio",
    email: "supplier#{i + 1}@example.com",
    phone_number: "#{11}97#{rand(100000..999999)}",
    status: 'ativo',
    product_category: ['cosmeticos', 'maquiagem', 'perfumaria', 'cabelo', 'acessorios'].sample
  )
  suppliers << supplier
end
puts "✓ #{suppliers.count} fornecedores criados"

# Seed Products
puts "\nCriando 30 produtos..."
products = []
product_names = [
  "Camiseta", "Calça Jeans", "Vestido", "Blusa", "Jaqueta",
  "Sapato", "Tênis", "Bolsa", "Mochila", "Cinto",
  "Perfume Feminino", "Batom", "Pó Compacto", "Sérum Facial", "Máscara Facial",
  "Livro", "Caderno", "Caneta", "Lápis", "Marcador",
  "Luminária", "Almofada", "Tapete", "Cortina", "Espelho",
  "Fone de Ouvido", "Carregador", "Capinha de Celular", "Teclado", "Mouse"
]

30.times do |i|
  product = Product.create!(
    name: product_names[i],
    code: "PROD#{i + 1}",
    supplier: suppliers.sample,
    description: "Descrição do produto #{i + 1}",
    active: true,
    brand: "Marca #{(i % 5) + 1}",
    color: ['Preto', 'Branco', 'Vermelho', 'Azul', 'Verde', 'Amarelo', 'Rosa', 'Roxo'].sample,
    sale_price: rand(50..500).to_f,
    category: ['beleza_cosmeticos', 'moda_acessorios', 'bem_estar_autocuidado', 'decoracao_casa', 'gastronomia_bebidas', 'livros_cultura', 'tecnologia_lifestyle', 'fitness_esportes'].sample,
    min_stock: rand(5..20),
    location: "Corredor #{(i % 3) + 1}, Prateleira #{(i % 4) + 1}",
    quantity_in: rand(50..200)
  )
  products << product
end
puts "✓ #{products.count} produtos criados"

# Seed ProductInputs
puts "\nCriando 30 entradas de produtos..."
30.times do |i|
  ProductInput.create!(
    product: products.sample,
    quantity: rand(100..500),
    unit_cost: rand(20..200).to_f,
    supplier: suppliers.sample,
    date_input: (1..60).to_a.sample.days.ago,
    notes: "Entrada #{i + 1}"
  )
end
puts "✓ 30 entradas de produtos criadas"

# Add more stock to each product to avoid insufficient stock errors
puts "\nAumentando estoque dos produtos..."
products.each do |product|
  ProductInput.create!(
    product: product,
    quantity: 500,
    unit_cost: rand(20..200).to_f,
    supplier: suppliers.sample,
    date_input: 1.day.ago,
    notes: "Ajuste de estoque"
  )
end
puts "✓ Estoque aumentado"

# Seed Services
puts "\nCriando 30 serviços..."
services = []
30.times do |i|
  service = Service.create!(
    name: "Serviço #{i + 1}",
    price: rand(50..500).to_f,
    active: 'ativo'
  )
  services << service
end
puts "✓ #{services.count} serviços criados"

# Seed Sales (50 vendas)
puts "\nCriando 50 vendas..."
sales = []
50.times do |i|
  sale_date = (1..60).to_a.sample.days.ago
  sale = Sale.create!(
    customer: customers.sample,
    employee: employees.sample,
    sale_date: sale_date,
    due_date: sale_date + rand(7..30).days,
    discount_percentage: [0, 0, 5, 10, 15, 20].sample,
    total_amount: rand(100..5000).to_f,
    payment_method: ['dinheiro', 'cartao_credito', 'cartao_debito', 'pix', 'transferencia', 'boleto'].sample,
    status: ['pago', 'pendente', 'cancelado', 'expirado'].sample,
    notes: "Venda #{i + 1}",
    paid_date: ['pago'].sample == 'pago' ? sale_date + rand(1..5).days : nil
  )
  sales << sale
end
puts "✓ #{sales.count} vendas criadas"

# Seed SaleProducts
puts "\nCriando produtos em vendas..."
sales.each do |sale|
  used_products = Set.new
  rand(1..4).times do |i|
    product = products.sample
    # Avoid duplicate product in the same sale
    while used_products.include?(product.id)
      product = products.sample
    end
    used_products.add(product.id)

    SaleProduct.create!(
      sale: sale,
      product: product,
      quantity: rand(1..5),
      unit_price: rand(50..500).to_f
    )
  end
end
puts "✓ Produtos adicionados às vendas"

# Seed SaleServices
puts "\nCriando serviços em vendas..."
sales.each do |sale|
  if rand(0..1) == 1
    SaleService.create!(
      sale: sale,
      service: services.sample,
      quantity: rand(1..3),
      unit_price: rand(50..300).to_f
    )
  end
end
puts "✓ Serviços adicionados às vendas"

# Seed ProductOutputs (automatically created via callback, but we'll add some manual ones)
puts "\nCriando saídas de produtos..."
sales.each do |sale|
  if sale.sale_products.any?
    sale.sale_products.each do |sale_product|
      ProductOutput.create!(
        product: sale_product.product,
        quantity: sale_product.quantity,
        output_type: 'venda',
        date_output: sale.sale_date,
        created_by: employees.sample,
        skip_stock_validation: true
      )
    end
  end
end
puts "✓ Saídas de produtos criadas"

# Print summary
puts "\n" + "="*60
puts "RESUMO DO SEED"
puts "="*60
puts "Usuários: #{User.count}"
puts "Funcionários: #{Employee.count}"
puts "Clientes: #{Customer.count}"
puts "Fornecedores: #{Supplier.count}"
puts "Produtos: #{Product.count}"
puts "Entradas de Produtos: #{ProductInput.count}"
puts "Serviços: #{Service.count}"
puts "Vendas: #{Sale.count}"
puts "Produtos em Vendas: #{SaleProduct.count}"
puts "Serviços em Vendas: #{SaleService.count}"
puts "Saídas de Produtos: #{ProductOutput.count}"
puts "="*60
puts "✓ Seed concluído com sucesso!"
