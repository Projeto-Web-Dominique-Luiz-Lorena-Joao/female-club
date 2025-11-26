namespace :stock do
  desc "Atualiza o stock_status de todos os produtos"
  task update_status: :environment do
    puts "🔄 Iniciando atualização do stock_status..."
    
    total = Product.count
    updated = 0
    
    Product.find_each.with_index do |product, index|
      old_status = product.stock_status
      product.update_stock_status!
      new_status = product.reload.stock_status
      
      if old_status != new_status
        updated += 1
        puts "  ✓ #{product.name}: #{old_status} → #{new_status}"
      end
      
      if (index + 1) % 10 == 0
        puts "  Processados: #{index + 1}/#{total}"
      end
    end
    
    puts "\nConcluído!"
    puts "   Total de produtos: #{total}"
    puts "   Atualizados: #{updated}"
    puts "   Mantidos: #{total - updated}"
  end

  desc "Mostra resumo do status de estoque"
  task summary: :environment do
    puts "\nResumo do Estoque:"
    puts "─" * 40
    
    {
      "Em Estoque" => "em_estoque",
      "Estoque Baixo" => "baixo",
      "Estoque Crítico" => "critico",
      "Fora de Estoque" => "fora_de_estoque"
    }.each do |label, status|
      count = Product.where(stock_status: status).count
      puts "  #{label.ljust(20)}: #{count}"
    end
    
    puts "─" * 40
    puts "  #{'Total'.ljust(20)}: #{Product.count}"
  end
end